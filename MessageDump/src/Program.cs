using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace MessageDump
{
    class Program
    {
        const String REGISTRATION_MESSAGE_PATTERN = ".*addon:(Register.*?)\\([\'\"](.*?)[\'\"].*?[\'\"](.*?)[\'\"]\\)";

        static void Main(string[] args)
        {
            if (args.Length > 0)
            {
                var dir = args[0];
                if (Directory.Exists(dir))
                {
                    var messages = ParseLua(dir);
                    StringBuilder tableBuilder = new StringBuilder();
                    tableBuilder.AppendLine("Message Name | Registration Method | Args | Origin");
                    tableBuilder.AppendLine("--- | --- | --- | ---");
                    foreach (var messageName in messages.Keys) {
                        StringBuilder rowBuilder = new StringBuilder();
                        rowBuilder.Append("`" + messageName + "` | ");
                        HashSet<String> origin = new HashSet<string>();
                        HashSet<String> arguments = new HashSet<string>();
                        HashSet<int> argCounts = new HashSet<int>();
                        HashSet<String> registrationType = new HashSet<string>();
                        foreach (var message in messages[messageName])
                        {
                            origin.Add(message.origin);
                            var argLength = message.args.Split(',').Length;
                            if (!argCounts.Contains(argLength))
                            {
                                argCounts.Add(argLength);
                                arguments.Add("`(" + message.args + ")`");
                            }
                            registrationType.Add("`" + message.registrationType + "`");
                        }
                        rowBuilder.Append(String.Join("<br>", registrationType) + " | ");
                        rowBuilder.Append(String.Join("<br>", arguments) + " | ");
                        rowBuilder.Append(String.Join("<br>", origin));
                        tableBuilder.AppendLine(rowBuilder.ToString());
                    }
                    File.WriteAllText("MessageDump.txt", tableBuilder.ToString());
                }
            }
        }

        static Dictionary<String, List<Message>> ParseLua(string directory)
        {
            DirectoryInfo patchDirectoryInfo = new DirectoryInfo(directory);
            var filenames = Directory.EnumerateFiles(directory, "*.lua", SearchOption.AllDirectories);
            Dictionary<String, List<Message>> messages = new Dictionary<String, List<Message>>();
            foreach (var filename in filenames)
            {
                var code = File.ReadAllText(filename);
                var matches = Regex.Matches(code, REGISTRATION_MESSAGE_PATTERN);
                foreach (Match match in matches)
                {
                    var regisType = match.Groups[1];
                    var messageName = match.Groups[2];
                    var targetFuncName = match.Groups[3];

                    var functionPattern = GenerateFunctionSearchPattern(targetFuncName.Value);
                    var functionMatch = Regex.Match(code, functionPattern);
                    var args = functionMatch.Groups[1].Value;
                    var message = new Message();
                    message.name = messageName.Value;
                    message.origin = Path.GetFileName(filename);
                    message.registrationType = regisType.Value;
                    message.args = args;
                    if (!messages.ContainsKey(message.name))
                    {
                        messages[message.name] = new List<Message>();
                    }
                    messages[message.name].Add(message);
                }
            }
            return messages;
        }

        static String GenerateFunctionSearchPattern(string funcName)
        {
            return String.Format("function\\s*{0}\\((.*)\\)", funcName);
        }
    }
}
