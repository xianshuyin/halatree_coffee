import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'general_response.dart';
part 'api.g.dart';

/*
*   This file will define all the endpoint to connect to API backend server
* */

@RestApi(baseUrl: "")

abstract class Api {
  factory Api(Dio dio, {String baseUrl}) = _Api;

  @POST("getnews")
  Future<GeneralResponse> getnews(
      // @Part(name: "user_email") String email,
      // @Part(name: "user_password") String password,
  );

  @FormUrlEncoded()
  @POST("halatreeusersignup")
  Future<GeneralResponse> halatreeusersignup(
    @Field("email") String email,
    @Field("user_name") String userName,
   // @Field("last_name") String lastName,
    @Field("password") String password,
  );

  @FormUrlEncoded()
  @POST("halatreeuserlogin")
  Future<GeneralResponse> halatreeuserlogin(
    @Field("email") String email,
    @Field("password") String password,
  );

  @FormUrlEncoded()
  @POST("getuserdata")
  Future<GeneralResponse> getuserdata(
    @Field("id") String userId
  );

  @FormUrlEncoded()
  @POST("updateuserprofile")
  Future<GeneralResponse> updateuserprofile(
    @Field("id") String userId,
    @Field("email") String email,
    @Field("user_name") String userName,
    //@Field("last_name") String lastName,
  );

  @FormUrlEncoded()
  @POST("requesthalatreeforgotpassword")
  Future<GeneralResponse> requesthalatreeforgotpassword(
    @Field("email") String email,
  );

  @FormUrlEncoded()
  @POST("changepassword")
  Future<GeneralResponse> changepassword(
    @Field("email") String email,
    @Field("otp") String otp,
    @Field("password") String newPassword,
  );

  @FormUrlEncoded()
  @POST("updatepassword")
  Future<GeneralResponse> updatepassword(
    @Field("user_id") String userId,
    @Field("password") String password,
  );

  @FormUrlEncoded()
  @POST("addcustomercredit")
  Future<GeneralResponse> addcustomercredit(
    @Field("customer_id") String customer_id,
    @Field("amount") String amount,
  );

  @FormUrlEncoded()
  @POST("deductcloverpoints")
  Future<GeneralResponse> deductcloverpoints(
    @Field("id") String userId,
    @Field("points") String points,
    @Field("redeem_code") String redeemCode,
  );

  @FormUrlEncoded()
  @POST("gettransactionhistory")
  Future<GeneralResponse> gettransactionhistory(
    @Field("id") String userId,
    @Field("redeem_type") String redeemType,
    @Field("source") String source,
  );

}
