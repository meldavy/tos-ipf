using Newtonsoft.Json;
using System;
using System.IO;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;

namespace TOSDump
{
    class Program
    {
        const String PROPERTY_FILE_NAME = "property.json";
        static void Main(string[] args)
        {
            if (!File.Exists(PROPERTY_FILE_NAME))
            {
                var filestream = File.Create(PROPERTY_FILE_NAME);
                filestream.Close();
            }
            var propertyJson = File.ReadAllText(PROPERTY_FILE_NAME);
            var props = JsonConvert.DeserializeObject<TOSDumpProperty>(propertyJson);
            if (props == null)
            {
                props = new TOSDumpProperty();
            }
            if (props.files == null)
            {
                props.files = new List<string>();
            }
            if (args.Length > 0)
            {
                if (!File.Exists("ipf_unpack.exe"))
                {
                    Console.Out.WriteLine("ipf_unpack.exe not found, must be in same dir");
                    return;
                }
                Console.WriteLine(args[0]);
                var tosdir = args[0];
                var patchPath = Path.Combine(tosdir, "patch");
                var dataPath = Path.Combine(tosdir, "data");
                if (!Directory.Exists(patchPath) || !Directory.Exists(dataPath))
                {
                    Console.Out.WriteLine(tosdir + " is not a valid TOS directorty!");
                    return;
                }
                DumpFiles(dataPath, props);
                DumpFiles(patchPath, props);
            }
            var propsSerialized = JsonConvert.SerializeObject(props, Formatting.Indented);
            File.WriteAllText(PROPERTY_FILE_NAME, propsSerialized);
            // cleanup directory
            var extractedPath = Path.Combine(Directory.GetCurrentDirectory(), "extract");
            var filenames = Directory.EnumerateFiles(extractedPath, "*.*", SearchOption.AllDirectories);
            foreach (var filename in filenames)
            {
                var extension = Path.GetExtension(filename);
                if (extension != ".lua" && extension != ".xml") {
                    File.Delete(filename);
                }
            }
            DeleteEmptyDirs(extractedPath);
        }

        static void DumpFiles(string directory, TOSDumpProperty props)
        {
            DirectoryInfo patchDirectoryInfo = new DirectoryInfo(directory);
            var filenames = Directory.EnumerateFiles(directory, "*.ipf", SearchOption.AllDirectories);
            List<string> sortedFileNames = new List<string>(filenames);
            sortedFileNames.Sort();
            foreach (var filename in sortedFileNames)
            {
                var simpleFileName = Path.GetFileName(filename);
                if (!props.files.Contains(simpleFileName))
                {
                    props.files.Add(simpleFileName);
                    DumpFile(filename);
                    Console.Out.WriteLine("Extracted " + simpleFileName);
                    break;
                }
            }
        }

        static void DumpFile(string filePath)
        {
            // decrypt
            var decryptProcess = new Process();
            var decryptProcessStartInfo = new ProcessStartInfo();
            decryptProcessStartInfo.FileName = "cmd.exe";
            decryptProcessStartInfo.Arguments = String.Format("/C ipf_unpack.exe \"{0}\" decrypt", filePath);
            decryptProcessStartInfo.RedirectStandardOutput = true;
            decryptProcess.StartInfo = decryptProcessStartInfo;
            decryptProcess.Start();
            var decryptOutput = decryptProcess.StandardOutput.ReadToEnd();
            decryptProcess.WaitForExit();
            Console.Out.WriteLine(decryptOutput);

            // extract
            var extractProcess = new Process();
            var extractProcessStartInfo = new ProcessStartInfo();
            extractProcessStartInfo.FileName = "cmd.exe";
            extractProcessStartInfo.Arguments = String.Format("/C ipf_unpack.exe \"{0}\" extract lua xml", filePath);
            extractProcessStartInfo.RedirectStandardOutput = true;
            extractProcess.StartInfo = extractProcessStartInfo;
            extractProcess.Start();
            var extractOutput = extractProcess.StandardOutput.ReadToEnd();
            extractProcess.WaitForExit();
            Console.Out.WriteLine(extractOutput);
        }

        static void DeleteEmptyDirs(string dir)
        {
            if (String.IsNullOrEmpty(dir))
                throw new ArgumentException(
                    "Starting directory is a null reference or an empty string",
                    "dir");

            try
            {
                foreach (var d in Directory.EnumerateDirectories(dir))
                {
                    DeleteEmptyDirs(d);
                }

                var entries = Directory.EnumerateFileSystemEntries(dir);
                
                if (!entries.Any())
                {
                    try
                    {
                        Directory.Delete(dir);
                    }
                    catch (UnauthorizedAccessException) { }
                    catch (DirectoryNotFoundException) { }
                }
            }
            catch (UnauthorizedAccessException) { }
        }
    }
}
