import types
import importlib.util
from pathlib import Path
import sys

analysis_path = Path(__file__).resolve().parents[1] / "scripts" / "analysis.py"
spec = importlib.util.spec_from_file_location("analysis", analysis_path)
analysis = importlib.util.module_from_spec(spec)

# Provide stub modules so analysis.py imports succeed without heavy dependencies.
sys.modules['MDAnalysis'] = types.SimpleNamespace()
dummy_spatial = types.SimpleNamespace(ConvexHull=lambda *args, **kwargs: None)
dummy_csgraph = types.SimpleNamespace(connected_components=lambda *args, **kwargs: (0, []))
dummy_sparse = types.SimpleNamespace(csgraph=dummy_csgraph)
sys.modules['scipy'] = types.SimpleNamespace(spatial=dummy_spatial, sparse=dummy_sparse)
sys.modules['scipy.spatial'] = dummy_spatial
sys.modules['scipy.sparse'] = dummy_sparse
sys.modules['scipy.sparse.csgraph'] = dummy_csgraph
spec.loader.exec_module(analysis)

class DummyTrajectory(list):
    pass

class DummyAtoms:
    residues = []

class DummyUniverse:
    def __init__(self, n_frames):
        self.trajectory = DummyTrajectory(range(n_frames))
    def select_atoms(self, *_):
        return DummyAtoms()


def test_find_cluster_frame_short_trajectory():
    dummy = DummyUniverse(10)
    assert analysis.find_cluster_frame(dummy) is None


def test_process_polymer_skips_when_cluster_frame_none(monkeypatch, tmp_path):
    polymer_dir = tmp_path / "poly"
    polymer_dir.mkdir()
    (polymer_dir / "20sim").mkdir()
    (polymer_dir / "20sim" / "20_interfaceafterpgn.psf").write_text("psf")
    (polymer_dir / "20sim" / "system.dcd").write_text("dcd")
    (polymer_dir / "modifybond.py").write_text("input_list = []")

    monkeypatch.setattr(analysis, "find_cluster_frame", lambda *_: None)
    monkeypatch.setattr(
        analysis.mda,
        "Universe",
        lambda *_, **__: DummyUniverse(0),
        raising=False,
    )
    result = analysis.process_polymer(str(polymer_dir), "analysis.tcl", 5)
    assert result is None
