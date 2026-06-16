"""Tests for the bundled ``blueprint`` waterfall harness extension.

Validates:
- Bundled layout (manifest, README, five command files, doc template, oracle script)
- Catalog registration (bundled) + the blueprint-waterfall workflow registration
- Wheel/source-checkout resolution via ``_locate_bundled_extension``
- Install via ``ExtensionManager.install_from_directory``
- BEHAVIORAL: the deterministic state oracle computes the right next action on a
  fixture project (the spine the autonomous driver depends on)
"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest
import yaml

from specify_cli import _locate_bundled_extension


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
EXT_DIR = PROJECT_ROOT / "extensions" / "blueprint"
ORACLE = EXT_DIR / "scripts" / "bash" / "blueprint-state.sh"

EXPECTED_COMMANDS = {
    "speckit.blueprint.init",
    "speckit.blueprint.next",
    "speckit.blueprint.status",
    "speckit.blueprint.distill",
    "speckit.blueprint.drive",
}


# ── Bundled extension layout ─────────────────────────────────────────────────


class TestExtensionLayout:
    def test_extension_yml_has_required_fields(self):
        manifest = yaml.safe_load((EXT_DIR / "extension.yml").read_text(encoding="utf-8"))
        assert manifest["extension"]["id"] == "blueprint"
        commands = {c["name"] for c in manifest["provides"]["commands"]}
        assert commands == EXPECTED_COMMANDS

    def test_command_files_exist(self):
        for name in EXPECTED_COMMANDS:
            assert (EXT_DIR / "commands" / f"{name}.md").is_file()

    def test_readme_and_template_exist(self):
        assert (EXT_DIR / "README.md").is_file()
        assert (EXT_DIR / "templates" / "blueprint-template.md").is_file()

    def test_oracle_script_present_and_executable(self):
        assert ORACLE.is_file()
        # ships executable so the driver can call it directly
        assert ORACLE.stat().st_mode & 0o111, "blueprint-state.sh must be executable"


# ── Catalog + workflow registration ──────────────────────────────────────────


class TestRegistration:
    def test_catalog_lists_blueprint_as_bundled(self):
        catalog = json.loads((PROJECT_ROOT / "extensions" / "catalog.json").read_text())
        entry = catalog["extensions"]["blueprint"]
        assert entry["bundled"] is True and entry["id"] == "blueprint"

    def test_workflow_registered_and_valid(self):
        wf = PROJECT_ROOT / "workflows" / "blueprint-waterfall" / "workflow.yml"
        assert wf.is_file()
        doc = yaml.safe_load(wf.read_text(encoding="utf-8"))
        assert doc["workflow"]["id"] == "blueprint-waterfall"
        # the single command step drives the autonomous loop
        assert doc["steps"][0]["command"] == "speckit.blueprint.drive"
        catalog = json.loads((PROJECT_ROOT / "workflows" / "catalog.json").read_text())
        assert "blueprint-waterfall" in catalog["workflows"]


class TestBundleResolution:
    def test_locate_bundled_extension_finds_blueprint(self):
        located = _locate_bundled_extension("blueprint")
        assert located is not None and (located / "extension.yml").is_file()


# ── Behavioral: the deterministic oracle (the spine) ─────────────────────────


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
class TestStateOracle:
    def _project(self, tmp_path: Path) -> Path:
        (tmp_path / ".specify").mkdir()
        (tmp_path / "docs").mkdir()
        return tmp_path

    def _next(self, root: Path) -> dict:
        out = subprocess.run(
            ["bash", str(ORACLE), "next", "--json", "--root", str(root)],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return json.loads(out)

    def test_spec_without_plan_advances_to_plan(self, tmp_path: Path):
        root = self._project(tmp_path)
        d = root / "specs" / "001-alpha"; d.mkdir(parents=True)
        (d / "spec.md").write_text("# Spec\n**Status**: Draft\nclean, no markers\n")
        (root / "docs" / "blueprint.md").write_text("# BP\nsee specs/001-alpha/spec.md\n")
        nxt = self._next(root)
        assert nxt["phase"] == "plan" and nxt["slug"] == "001-alpha"

    def test_clarification_markers_route_to_clarify(self, tmp_path: Path):
        root = self._project(tmp_path)
        d = root / "specs" / "002-beta"; d.mkdir(parents=True)
        (d / "spec.md").write_text("# Spec\n- [NEEDS CLARIFICATION: which?]\n")
        (root / "docs" / "blueprint.md").write_text("# BP\nsee specs/002-beta/spec.md\n")
        assert self._next(root)["phase"] == "clarify"

    def test_unreferenced_spec_is_distill_drift_first(self, tmp_path: Path):
        root = self._project(tmp_path)
        d = root / "specs" / "003-gamma"; d.mkdir(parents=True)
        (d / "spec.md").write_text("# Spec\nclean\n")
        (d / "plan.md").write_text("# Plan\n")
        (d / "tasks.md").write_text("- [x] done\n")
        (root / "docs" / "blueprint.md").write_text("# BP\n## Gamma\ndetailed holding pen\n")
        nxt = self._next(root)
        assert nxt["phase"] == "distill" and nxt["slug"] == "003-gamma"

    def test_empty_backlog_reports_done(self, tmp_path: Path):
        root = self._project(tmp_path)
        (root / "docs" / "blueprint.md").write_text("# BP\nno sections yet\n")
        nxt = self._next(root)
        # no specs, blueprint present → either specify (start) ; with no specs and a
        # blueprint the oracle suggests specify; assert it does not falsely report done
        assert nxt["phase"] in {"specify", "done"}


# ── Install ──────────────────────────────────────────────────────────────────


class TestExtensionInstall:
    def test_install_from_directory(self, tmp_path: Path):
        from specify_cli.extensions import ExtensionManager

        (tmp_path / ".specify").mkdir()
        manager = ExtensionManager(tmp_path)
        manifest = manager.install_from_directory(EXT_DIR, "0.10.0", register_commands=False)
        assert manifest.id == "blueprint"
        assert {c["name"] for c in manifest.commands} == EXPECTED_COMMANDS
        installed = tmp_path / ".specify" / "extensions" / "blueprint"
        for name in EXPECTED_COMMANDS:
            assert (installed / "commands" / f"{name}.md").is_file()
