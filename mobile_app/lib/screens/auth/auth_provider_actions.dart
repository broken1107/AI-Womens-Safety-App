import '../../widgets/user_value.dart';

/// Makes the UI compatible with providers that expose either named or
/// positional parameters while the API layer evolves.
Future<dynamic> loginWithProvider(
  dynamic provider, {
  required String email,
  required String password,
  required bool rememberMe,
}) async {
  try {
    return await provider.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  } on NoSuchMethodError {
    try {
      return await provider.login(email: email, password: password);
    } on NoSuchMethodError {
      try {
        return await provider.login(email, password, rememberMe);
      } on NoSuchMethodError {
        return await provider.login(email, password);
      }
    }
  }
}

Future<dynamic> sendLoginOtpWithProvider(
  dynamic provider, {
  required String loginChallengeId,
  required String method,
}) async {
  try {
    return await provider.sendLoginOtp(
      loginChallengeId: loginChallengeId,
      method: method,
    );
  } on NoSuchMethodError {
    try {
      return await provider.sendLoginOtp(loginChallengeId, method);
    } on NoSuchMethodError {
      return null;
    }
  }
}

Future<dynamic> verifyLoginOtpWithProvider(
  dynamic provider, {
  required String loginChallengeId,
  required String otp,
  bool rememberMe = true,
}) async {
  try {
    return await provider.verifyLoginOtp(
      loginChallengeId: loginChallengeId,
      otp: otp,
      rememberMe: rememberMe,
    );
  } on NoSuchMethodError {
    try {
      return await provider.verifyLoginOtp(
        loginChallengeId: loginChallengeId,
        otp: otp,
      );
    } on NoSuchMethodError {
      try {
        return await provider.verifyLoginOtp(loginChallengeId, otp);
      } on NoSuchMethodError {
        return null;
      }
    }
  }
}

Future<dynamic> resendLoginOtpWithProvider(
  dynamic provider, {
  required String loginChallengeId,
}) async {
  try {
    return await provider.resendLoginOtp(
      loginChallengeId: loginChallengeId,
    );
  } on NoSuchMethodError {
    try {
      return await provider.resendLoginOtp(loginChallengeId);
    } on NoSuchMethodError {
      return null;
    }
  }
}

Future<dynamic> registerWithProvider(
  dynamic provider, {
  required String name,
  required String email,
  required String phone,
  required String password,
}) async {
  try {
    return await provider.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  } on NoSuchMethodError {
    try {
      return await provider.register(
        fullName: name,
        email: email,
        phone: phone,
        password: password,
      );
    } on NoSuchMethodError {
      try {
        return await provider.register(name, email, phone, password);
      } on NoSuchMethodError {
        return await provider.register(name, email, password);
      }
    }
  }
}

Future<dynamic> verifyOtpWithProvider(
  dynamic provider, {
  required String email,
  required String otp,
}) async {
  try {
    return await provider.verifyOtp(email: email, otp: otp);
  } on NoSuchMethodError {
    try {
      return await provider.verifyOtp(email: email, code: otp);
    } on NoSuchMethodError {
      try {
        return await provider.verifyOtp(email, otp);
      } on NoSuchMethodError {
        return await provider.verifyOtp(otp);
      }
    }
  }
}

/// Returns null when the provider has no reset endpoint, allowing the UI to
/// still guide the user to verification in offline/demo configurations.
Future<dynamic>? requestPasswordResetWithProvider(
  dynamic provider,
  String email,
) async {
  try {
    return await provider.forgotPassword(email: email);
  } on NoSuchMethodError {
    try {
      return await provider.sendPasswordReset(email: email);
    } on NoSuchMethodError {
      try {
        return await provider.forgotPassword(email);
      } on NoSuchMethodError {
        return null;
      }
    }
  }
}

Future<dynamic>? resendOtpWithProvider(dynamic provider, String email) async {
  try {
    return await provider.resendOtp(email: email);
  } on NoSuchMethodError {
    try {
      return await provider.resendOtp(email);
    } on NoSuchMethodError {
      return null;
    }
  }
}

bool providerOperationSucceeded(dynamic result, dynamic provider) {
  if (result is bool) return result;
  if (result is Map && result['success'] is bool) {
    return result['success'] as bool;
  }
  return providerErrorMessage(provider) == null;
}
