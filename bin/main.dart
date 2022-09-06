import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:http/http.dart';
import 'package:onboard_binary/at_onboarding_constants.dart';
import 'package:onboard_binary/free_atsign_service.dart';

void _printInstructions() {
  print('''
  This tool will help you generate your .atKeys file for your atSign.

  Usage: at_onboarding_cli --atsign <atSign> --email <email>
  Optional:
  --root <rootDomain e.g. root.atsign.org>
  --port <port number e.g. 64>
  --verbose flag
  ''');
}

String formatAtSign(String atSign) {
  if(!atSign.startsWith('@')) {
    return '@$atSign';
  }
  return atSign;
}

String withoutPrefixAtSign(String atSign) {
  if(atSign.startsWith('@')) {
    return atSign.substring(1);
  }
  return atSign;
}

void main(List<String> args) async {
  if(args.length < 4) {
    _printInstructions();
    exit(0);
  }
  final parser = ArgParser();

  parser.addOption('atsign', abbr: 'a', mandatory: true, help: 'atSign to generate .atKeys for e.g. @alice'); // e.g. '@alice'
  parser.addOption('email', abbr: 'e', mandatory: true, help: 'email that the atSign is purchased with, e.g. bob@atsign.com'); // e.g. 'bob@atsign.com'
  parser.addOption('root', abbr: 'r', mandatory: false, help: 'e.g. \'root.atsign.org\'', defaultsTo: 'root.atsign.org');  // e.g. 'root.atsign.org'
  parser.addOption('port', abbr: 'p', mandatory: false, help: 'e.g. 64', defaultsTo: '64'); // e.g. 64
  parser.addFlag('verbose', abbr: 'v', help: 'verbose output', defaultsTo: false);

  var results = parser.parse(args);

  final String atSign = results['atsign'];
  final String email = results['email'];
  final String rootHost = results['root'] ?? 'root.atsign.org';
  final int rootPort = int.parse(results['port']);
  final bool verbose = results['verbose'] == 'true';

  AtOnboardingConstants.rootDomain = rootHost;
  const String apiKey = AtOnboardingConstants.deviceapikey;
  AtOnboardingConstants.setApiKey(apiKey);

  final FreeAtsignService service = FreeAtsignService();
  final Response response = await service.loginWithAtsign(formatAtSign(atSign));

  if(verbose) { 
    print('response: ${response.body}'); 
  }
  print('Enter OTP sent to $email:');
  var line = stdin.readLineSync();
  var otp = line!.trim().replaceAll('\n', '');
  if(verbose) { 
    print('atSign: \'$atSign\' otp: \'$otp\''); 
  }
  final Response cramResponse = await service.verificationWithAtsign(withoutPrefixAtSign(atSign), otp);
  var res = cramResponse.body;
  var jsonDecoded = jsonDecode(res);
  var cramKey = (jsonDecoded['cramkey'] as String).split(":")[1];
  if(verbose) { print('CRAM Key: $cramKey'); }
  String os = Platform.operatingSystem;
  if(verbose) { print('OS: $os'); }
  if(verbose) { print(Platform.environment['HOME']); }
  final String home = Platform.environment['HOME']!;
  final AtOnboardingPreference preference = AtOnboardingPreference()
    ..atKeysFilePath = Directory.fromUri(Uri.directory('${home}/.atsign/keys/', windows: false)).path
    ..commitLogPath = Directory.fromUri(Uri.directory('${home}/.atsign/logs/', windows: false)).path
    ..hiveStoragePath = Directory.fromUri(Uri.directory('${home}/.atsign/hive/', windows: false)).path
    ..downloadPath = Directory.fromUri(Uri.directory('${home}/.atsign/keys/', windows: false)).path
    ..rootDomain = rootHost
    ..rootPort = rootPort
	  ..cramSecret = cramKey
    ..isLocalStoreRequired = true
	;
  final AtOnboardingService atOnboardingService =
      AtOnboardingServiceImpl(atSign, preference);
  atOnboardingService.onboard();
  print('.atKeys generated!');
}
