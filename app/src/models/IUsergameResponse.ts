export interface IOfferResponse{
    orig_set: number[]
    flip_set: number[]
}

export default interface IUsergameResponse{
    balance: number
    moves: number
    level: number
    col_set: number[]
    own_set: number[]
    offer_set: IOfferResponse[]
}