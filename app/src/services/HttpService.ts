import axios from 'axios'
import IAuthResponse from "../models/IAuthResponse"

export const API_URL = "http://localhost:8081/"

const HttpService = axios.create({
    withCredentials: true,
    baseURL: API_URL,
    /* headers: {
        'content-type': 'application/json',
        'Authorization': 'null',
    } */
})

HttpService.interceptors.request.use(
    (config) => {
        const token: string | null = localStorage.getItem('session')
        if (token !== null) {
            config!.headers!.Authorization =  "Bearer " + token
        } else {
            config!.headers!.Authorization =  'null'
        }
        return config;
    }
)

HttpService.interceptors.response.use(
    (config) => {
        return config
    },
    async (error) => {
        /* const originalRequest = error.config;
        if (error.response.status == 401 && error.config && !error.config._isRetry) {
            originalRequest._isRetry = true;
            try {
                const response = await axios.get<IAuthResponse>(`${API_URL}/refresh`, {withCredentials: true})
                localStorage.setItem('token', response.data.accessToken);
                return $api.request(originalRequest);
            } catch (e) {
                console.log('НЕ АВТОРИЗОВАН')
            }
        } */
        throw error
    }
)

export default HttpService
