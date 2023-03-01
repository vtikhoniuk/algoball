import IUsergame, {IOffer} from "../models/IUsergame"
import {IOfferResponse} from "../models/IUsergameResponse"

export default class GameViewService{
    static getImagePath(suit: number, activity: boolean): string {
        return (
            './img/' + 
            String(suit).substring(0,3) + '/' + 
            String(suit).substring(3) + 
            (activity ? '1' : '2') +
            '.png'
        )
    }

    static isPersistent(suit: number): boolean {
        return String(suit).substring(4) === '2' // Is not burned when offer applied
    }

    static isGold(suit: number): boolean {
        return String(suit).substring(3,4) === '9' // Just gold
    }

    static isCard(suit: number): boolean {
        return suit < 90000
    }

    static isCoin(suit: number): boolean {
        return String(suit).substring(0,4) === '9011' 
    }

    static isLootbox(suit: number): boolean {
        return String(suit).substring(0,4) === '9021' 
    }

    static isArrow(suit: number): boolean {
        return String(suit).substring(0,4) === '9901' 
    }

    static isShiftRequired(previousSuit: number | undefined, currentSuit: number): boolean {
        //return (previousSuit !== undefined && this.isBurned(previousSuit) && this.isBurned(currentSuit))
        //return ((previousSuit !== undefined && !this.isCard(previousSuit)) || !this.isCard(currentSuit))
        //return (previousSuit !== undefined && this.isArrow(previousSuit))
        return false
    }

    static getBaseSuit(suit: number): number {
        return Number(String(suit).substring(0,4)) 
    }

    static getPersistentSuit(suit: number): number {
        return Number(String(suit).substring(0,4)+'2')
    }

    static getBurnedSuit(suit: number): number {
        return Number(String(suit).substring(0,4)+'1')
    }

    static getArrowSuit(): number{
        return 99011
    }

    static calculateActivity(usergame: IUsergame) {
        const set: number[] = [] 
        for (const colCard of usergame.colSet){
            colCard.activity = true
            const persistentIndex: number = usergame.ownSet.findIndex((card, cardIndex) => {
                if (card.suit === GameViewService.getPersistentSuit(colCard.suit)){
                    return (set.findIndex((c) => c === cardIndex) === -1)
                }
            })
            if (persistentIndex !== -1){
                set.push(persistentIndex)
                colCard.activity = false
            } else {
                const burnedIndex: number = usergame.ownSet.findIndex((card, cardIndex) => {
                    if (card.suit === GameViewService.getBurnedSuit(colCard.suit)){
                        return (set.findIndex((c) => c === cardIndex) === -1)
                    }
                }) 
                if (burnedIndex !== -1){
                    set.push(burnedIndex)
                    colCard.activity = false
                }
            }
        }

        for (let i=0; i<usergame.ownSet.length; i++){
            const index: number = set.findIndex((j) => i === j)
            if (index !== -1){
                usergame.ownSet[i].activity = false
            } else {
                usergame.ownSet[i].activity = true
            }
        }

        for (const offer of usergame.offerSet) {
            offer.activity = true
            const set: number[] = [] 
            for (const offerCard of offer.originalSet){
                if (GameViewService.isCoin(offerCard.suit) && usergame.balance > 0){
                    break
                } else {
                    const index: number = usergame.ownSet.findIndex((card, cardIndex) => {
                        if (GameViewService.getBaseSuit(card.suit) === GameViewService.getBaseSuit(offerCard.suit)){
                            return (set.findIndex((c) => c === cardIndex) === -1)
                        }
                    })
                    if (index !== -1){
                        set.push(index)
                        //break
                    } else {
                        offer.activity = false
                        break
                    }
                }
            }
        }
    }
}