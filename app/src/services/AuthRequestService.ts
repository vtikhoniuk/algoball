import HttpService from "./HttpService";
import {AxiosResponse} from 'axios';
import IAuthResponse from "../models/IAuthResponse";

export default class AuthRequestService{
    static async signin(email?: string, password?: string): Promise<AxiosResponse<IAuthResponse>> {
        return HttpService.post<IAuthResponse>('/signin', {email, password})
    }

    static async signup(email?: string, password?: string): Promise<AxiosResponse<IAuthResponse>> {
        return HttpService.post<IAuthResponse>('/signup', {email, password})
    }

    static async signout(): Promise<void> {
        return HttpService.post('/signout')
    }

    static async check(session: string): Promise<AxiosResponse<IAuthResponse>> {
        return HttpService.post<IAuthResponse>('/check', {session})
    }

    static isAuthError(error: string): boolean{
        return (
            error == 'USER_NOT_FOUND' ||
            error == 'NOT_AUTHENTICATED' ||
            error == 'WRONG_SESSION_SIGN'            
        )
    }
}