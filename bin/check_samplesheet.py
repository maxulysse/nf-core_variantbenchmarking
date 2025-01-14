#!/usr/bin/env python3

import os
import sys
import errno
import argparse


def parse_args(args=None):
    Description = "Reformat samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = f"ERROR: Please check samplesheet -> {error}"
    if context != "" and context_str != "":
        error_str = f"ERROR: Please check samplesheet -> {error}\n{context.strip()}: '{context_str.strip()}'"
    print(error_str)
    sys.exit(1)


def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:
    test_vcf,caller
    test1.vcf,manta
    test2.vcf,svaba
    For an example see:
    https://github.com/ghga-de/nf-benchmark/assets/samplesheet.csv
    """

    sample_mapping_dict = {}
    with open(file_in, "r", encoding='utf-8-sig') as fin:

        ## Check header
        MIN_COLS = 2
        HEADER = ["test_vcf","caller"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print(
                f"ERROR: Please check samplesheet header -> {','.join(header)} != {','.join(HEADER)}"
            )
            sys.exit(1)

        ## Check caller entries
        for line in fin:
            if line.strip():
                lspl = [x.strip().strip('"') for x in line.strip().split(",")]

                ## Check valid number of columns per row
                if len(lspl) < len(HEADER):
                    print_error(
                        f"Invalid number of columns (minimum = {len(HEADER)})!",
                        "Line",
                        line,
                    )

                num_cols = len([x for x in lspl if x])
                if num_cols < MIN_COLS:
                    print_error(
                        f"Invalid number of populated columns (minimum = {MIN_COLS})!",
                        "Line",
                        line,
                    )

                ## Check caller name entries
                test_vcf, caller = lspl[: len(HEADER)]
                if caller.find(" ") != -1:
                    print(
                        f"WARNING: Spaces have been replaced by underscores for caller: {caller}"
                    )
                    caller = caller.replace(" ", "_")
                if not caller:
                    print_error("Caller entry has not been specified!", "Line", line)

                sample_info = []  ## [test_vcf, caller ]

                sample_info = [test_vcf, caller]

                ## Create caller mapping dictionary = {caller: [[test_vcf, caller ]]}
                if caller not in sample_mapping_dict:
                    sample_mapping_dict[caller] = [sample_info]
                else:
                    if sample_info in sample_mapping_dict[caller]:
                        print_error("Samplesheet contains duplicate rows!", "Line", line)
                    else:
                        sample_mapping_dict[caller].append(sample_info)

    ## Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(
                ",".join(["test_vcf","caller"])
                + "\n"
            )
            for caller in sorted(sample_mapping_dict.keys()):

                for idx, val in enumerate(sample_mapping_dict[caller]):
                    fout.write(",".join(val) + "\n")
    else:
        print_error(f"No entries to process!", "Samplesheet: {file_in}")


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
