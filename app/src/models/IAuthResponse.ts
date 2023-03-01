/* export default interface IAuthResponse {
    accessToken: string;
    // refreshToken: string;
    user: IUser;
} */

export default interface IAuthResponse {
    session: string
    user_uuid: string
    email?: string
}
