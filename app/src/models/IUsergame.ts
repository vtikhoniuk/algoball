export interface ICard{
    suit: number
    activity?: boolean
    shift?: boolean
}

export interface IOffer{
    originalSet: ICard[]
    flipSet: ICard[]
    arrowShift?: boolean
    activity?: boolean
    itemCount: number
    shiftCount: number
}

export default interface IUsergame{
    balance: number
    moves: number
    level: number
    colSet: ICard[]
    ownSet: ICard[]
    offerSet: IOffer[]
    moveSet: IOffer[]
}