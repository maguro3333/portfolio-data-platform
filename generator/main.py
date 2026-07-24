from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List, Optional

from generator.config import load_settings
from generator.generate import generate_all
from generator.io import RawTableWriter
from generator.quality import build_reports


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    package_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(
        description="Generate deterministic EC portfolio raw CSV data."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=package_dir / "config.yaml",
        help="Generator configuration YAML.",
    )
    parser.add_argument(
        "--contract",
        type=Path,
        default=package_dir / "schema_contract.yaml",
        help="Logical schema contract YAML.",
    )
    parser.add_argument(
        "--scale",
        choices=("smoke", "full"),
        help="Override config.yaml scale.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        help="Override data/raw output directory.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace existing generated table directories.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> None:
    args = parse_args(argv)
    settings = load_settings(
        config_path=args.config,
        contract_path=args.contract,
        scale_override=args.scale,
        output_override=args.output_root,
    )
    if args.overwrite:
        settings.config["output"]["overwrite"] = True
    writer = RawTableWriter(
        output_root=settings.output_root,
        contract=settings.contract,
        overwrite=bool(settings.config["output"]["overwrite"]),
    )
    print(
        f"Generating scale={settings.scale_name} seed={settings.config['seed']} "
        f"into {settings.output_root}"
    )
    summary = generate_all(settings, writer)
    profile_path, quality_path, passed = build_reports(settings, writer, summary)
    print(f"Profile: {profile_path}")
    print(f"Quality: {quality_path}")
    print(f"Quality status: {'PASS' if passed else 'FAIL'}")
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
