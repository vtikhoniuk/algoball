import HttpService from "./HttpService"
import {AxiosResponse} from 'axios'
import IUsergameResponse from "../models/IUsergameResponse"

export default class CommonService{
    static getCssVar(v: string): string {
        return getComputedStyle(document.getElementById('root')!).getPropertyValue(v)
    }

    static getCssVarNum(v: string): number {
        return Number(this.getCssVar(v))
    }

    static getCssVarValue(v: string): number {
        const value: string = this.getCssVar(v)
        return Number(value.substring(0,value.length-2))
    }
}