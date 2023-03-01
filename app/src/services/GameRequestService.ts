import HttpService from "./HttpService"
import {AxiosResponse} from 'axios'
import IUsergameResponse, {IOfferResponse} from "../models/IUsergameResponse"
import {IOffer} from "../models/IUsergame"

export default class GameRequestService{
    static async getUsergame(user_uuid: string): Promise<AxiosResponse<IUsergameResponse>> {
        return HttpService.post<IUsergameResponse>('/usergame', {user_uuid})
    }

    static async getNextLevel(user_uuid: string, move_set: IOfferResponse[]): Promise<AxiosResponse<IUsergameResponse>> {
        return HttpService.post<IUsergameResponse>('/next_level', {user_uuid, move_set}, {timeout: 300000})
    }
    
    static convertOfferSetToRequest(offerSet: IOffer[]): IOfferResponse[] {
        const offer_response: IOfferResponse[] = []
        for (const offer of offerSet){
            const orig_set: number[] = []
            const flip_set: number[] = []
            for (const card of offer.originalSet){
                orig_set.push(card.suit)
            }
            for (const card of offer.flipSet){
                flip_set.push(card.suit)
            }
            offer_response.push({
                orig_set: orig_set, 
                flip_set: flip_set
            })
        }

        console.log('offer_response: ' + offer_response)
        return offer_response
    }
}