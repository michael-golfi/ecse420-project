import std.file : readText;
import std.stdio : writeln, File;
import std.algorithm.searching : countUntil, findSkip;
import std.regex : regex, matchAll;
import std.path : setExtension;

void main(string[] args) {
    // Read the output log
    assert (args.length == 2, "Expected a single argument");
    auto inputFileName = args[1];
    auto rawOutput = readText(inputFileName);
    // Next find where the "step 0" line is and discard all before it
    auto index = rawOutput.countUntil(": step 0, ");
    assert (index >= 0);
    rawOutput = rawOutput[index .. $];
    // We'll ignore step 0 since we don't know when it started, so get the end of the line
    assert(rawOutput.findSkip("\n"));
    // Now we actually parse the log lines, so first here's a nice regex to get all the fields we want
    auto lineRegex = (r"^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}\.\d{6}): step (\d+), loss = (\d+.\d{2}) "
            ~ r"\((\d+\.\d) examples/sec; (\d+\.\d{3}) sec/batch\)$").regex("m");
    // Create the file name for the output file
    auto outputFileName = inputFileName.setExtension("csv");
    // Open the file for writing
    auto outputFile = File(outputFileName, "w");
    // We'll use comma delimiters for our CSV columns
    enum colDelim = ',';
    // CSV normally use CR LF to delimite rows
    enum rowDelim = "\r\n";
    // Write the CSV column names for the first row
    outputFile.write("time", colDelim, "step", colDelim, "loss", colDelim,
            "examples/sec", colDelim, "sec/batch", rowDelim);
    // Now apply the regex to all the lines and output the fields as nice CSV
    foreach (lineFields; rawOutput.matchAll(lineRegex)) {
        assert(lineFields.length == 7);
        // Write the date in ISO 8601 format
        outputFile.write(lineFields[1], 'T', lineFields[2], colDelim);
        // Next write the step, loss, examples/sec and sec/batch
        outputFile.write(lineFields[3], colDelim, lineFields[4], colDelim, lineFields[5], colDelim, lineFields[6]);
        // Terminate the CSV row
        outputFile.write(rowDelim);
    }
}
