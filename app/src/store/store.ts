import {makeAutoObservable} from "mobx";
import IUser from "../models/IUser";
import IUsergame, {ICard, IOffer} from "../models/IUsergame";
import IUsergameResponse, {IOfferResponse} from "../models/IUsergameResponse";
import AuthRequestService from "../services/AuthRequestService";
import GameRequestService from "../services/GameRequestService";
import GameViewService from "../services/GameViewService";

export interface IStore {
    store: Store
}

export enum UserStatus{
    Undefined,
    New,
    SigninNeeded,
    Anonymous,
    Full,
    Win,
    Loss,
    Error
}

export default class Store {
    user: IUser | undefined
    usergame: IUsergame | undefined
    userStatus: UserStatus = UserStatus.Undefined
    isLoading: boolean = false

    constructor() {
        makeAutoObservable(this);
    }

    setUser(user: IUser | undefined) {
        this.user = user
    }

    setUserStatus(status: UserStatus) {
        console.log('Set user status -> ' + UserStatus[status])
        this.userStatus = status
    }
    
    setLoading(bool: boolean) {
        this.isLoading = bool
    }
    
    setUsergame(usergameResponse: IUsergameResponse | undefined) {
        if (usergameResponse === undefined){
            this.usergame = undefined
            return
        }

        const colSet: ICard[] = []
        for (const colResponse of usergameResponse.col_set){
            colSet.push({
                suit: colResponse
            })
        }

        const ownSet: ICard[] = []
        for (const cardResponse of usergameResponse.own_set){
            ownSet.push({
                suit: cardResponse
            })
        }

        const offerSet: IOffer[] = []
        for (const offerResponse of usergameResponse.offer_set) {
            let shift: boolean
            let itemCount: number = 0
            let shiftCount: number = 0
            const originalSet: ICard[] = []
            let previousSuit: number | undefined

            for (const originalCardResponse of offerResponse.orig_set){
                if (GameViewService.isShiftRequired(previousSuit, originalCardResponse)){
                    shift = true
                    shiftCount++
                } else {
                    shift = false
                }
                itemCount++
                originalSet.push({
                    suit: originalCardResponse,
                    shift: shift
                })
                previousSuit = originalCardResponse
            }

            let arrowShift: boolean = false
            if (GameViewService.isShiftRequired(previousSuit, GameViewService.getArrowSuit())){
                arrowShift = true
                shiftCount++
            } else {
                arrowShift = false
            }
            itemCount++

            previousSuit = undefined
            const flipSet: ICard[] = []
            for (const cardResponse of offerResponse.flip_set){
                if (GameViewService.isShiftRequired(
                        (previousSuit !== undefined ? previousSuit : GameViewService.getArrowSuit()), 
                        cardResponse
                )){
                    shift = true
                    shiftCount++
                } else {
                    shift = false
                }
                itemCount++
                flipSet.push({
                    suit: cardResponse,
                    shift: shift
                })
                previousSuit = cardResponse
            }
            offerSet.push({
                originalSet: originalSet, 
                flipSet: flipSet,
                arrowShift: arrowShift,
                itemCount: itemCount,
                shiftCount: shiftCount
            })        
        }

        this.usergame = {
            colSet: colSet,
            ownSet: ownSet,
            offerSet: offerSet,
            moveSet: [],
            balance: usergameResponse.balance,
            moves: usergameResponse.moves,
            level: usergameResponse.level
        }

        GameViewService.calculateActivity(this.usergame)
        console.log("usergame = " +  JSON.stringify(this.usergame))
    }

    applyOffer(index: number){
        const cardToBurnSet: number[] = [] // Indexes of burned card to delete
        const cardToMarkSet: number[] = [] // Indexes of persistent card which only marked
        const offer: IOffer = this.usergame!.offerSet[index]
        for (const offerCard of offer.originalSet){
            if (GameViewService.isCoin(offerCard.suit) && this.usergame!.balance > 0){
                this.usergame!.balance--
            } else {
                const persistentIndex: number = this.usergame!.ownSet.findIndex((card, cardIndex) => {
                    if (card.suit === GameViewService.getPersistentSuit(offerCard.suit)){
                        return (cardToMarkSet.findIndex((cardToMark) => cardToMark === cardIndex) === -1)
                    }
                })
                if (persistentIndex !== -1){
                    cardToMarkSet.push(persistentIndex)
                } else {
                    const burnedIndex: number = this.usergame!.ownSet.findIndex((card, cardIndex) => {
                        if (card.suit === GameViewService.getBurnedSuit(offerCard.suit)){
                            return (cardToBurnSet.findIndex((cardToBurn) => cardToBurn === cardIndex) === -1)
                        }
                    }) 
                    if (burnedIndex !== -1){
                        cardToBurnSet.push(burnedIndex)
                    } else {
                        console.log("Warning! Incorrect offer")
                    }
                }
            }
        }
        for (let i = 0; i<cardToBurnSet.length; i++){
            this.usergame!.ownSet.splice(cardToBurnSet[i]-i, 1)
        }
        for (const offerCard of offer.flipSet){
            if (GameViewService.isCoin(offerCard.suit)){
                this.usergame!.balance++
            } else {
                this.usergame!.ownSet.push(offerCard)
            }
        }
        this.usergame!.moveSet.push(this.usergame!.offerSet[index])
        this.usergame!.offerSet.splice(index, 1)
        this.usergame!.moves--

        GameViewService.calculateActivity(this.usergame!)

        // Check that collection is complete
        const set: number[] = []
        for (const colCard of this.usergame!.colSet){
            const index: number = this.usergame!.ownSet.findIndex((card, cardIndex) => {
                if (GameViewService.getBaseSuit(card.suit) === GameViewService.getBaseSuit(colCard.suit)){
                    return (set.findIndex((c) => c === cardIndex) === -1)
                }
            })
            if (index !== -1){
                set.push(index)
            } else {
                const goldIndex: number = this.usergame!.ownSet.findIndex((card, cardIndex) => {
                    if (GameViewService.isGold(card.suit)){
                        return (set.findIndex((c) => c === cardIndex) === -1)
                    }
                })
                if (goldIndex !== -1){
                    set.push(goldIndex)
                }    
            }
        }
        if (this.usergame!.colSet.length === set.length){
            // Win!
            console.log("You win!")
            this.setUserStatus(UserStatus.Win)
        } else if (this.usergame!.moves === 0){
            console.log("Moves run out. Try Again!")
            this.setUserStatus(UserStatus.Loss)
        } else {
            const index: number = this.usergame!.offerSet.findIndex((offer) => {
                return (offer.activity === true)
            })
            if (index === -1){
                console.log("No available moves. Try Again!")
                this.setUserStatus(UserStatus.Loss)
            }    
        }
    }

    async nextLevel() {
        try {
            this.setLoading(true)
            const user_uuid: string = this.user!.user_uuid
            console.log("*** moveSet = " + this.usergame!.moveSet)
            const move_set: IOfferResponse[] = GameRequestService.convertOfferSetToRequest(this.usergame!.moveSet)
            console.log("*** move_set = " + move_set)
            const response = await GameRequestService.getNextLevel(user_uuid, move_set)
            console.log(response)
            if (this.user!.email !== undefined) {
                this.setUserStatus(UserStatus.Full)
            } else {
                this.setUserStatus(UserStatus.Anonymous)
            }
            const usergameResponse: IUsergameResponse = response.data
            this.setUsergame(usergameResponse)    
        } catch (e: any) {
            console.log(e.response?.data?.error)
            if (AuthRequestService.isAuthError(e.response?.data?.error)){
                this.setUserStatus(UserStatus.SigninNeeded)
            } else {
                this.setUserStatus(UserStatus.Error)
            }
            this.setUser(undefined)
            this.setUsergame(undefined)
        } finally {
            this.setLoading(false)
        }
    }

    async signin(email?: string, password?: string) {
        try {
            this.setLoading(true)
            const response = await AuthRequestService.signin(email, password)
            console.log(response)
            localStorage.setItem('session', response.data.session)
            const user_uuid: string = response.data.user_uuid
            this.setUser({
                user_uuid,
                email
            })
            if (email !== undefined) {
                this.setUserStatus(UserStatus.Full)
            } else {
                this.setUserStatus(UserStatus.Anonymous)
            }
        } catch (e: any) {
            console.log(e.response?.data?.error)
        } finally {
            this.setLoading(false)
        }
    }

    async signup(email?: string, password?: string) {
        try {
            this.setLoading(true)

            const response = await AuthRequestService.signup(email, password)
            console.log(response)
            localStorage.setItem('session', response.data.session)
            const user_uuid: string = response.data.user_uuid
            
            const response2 = await GameRequestService.getUsergame(user_uuid)
            console.log(response2)

            this.setUser({
                user_uuid,
                email
            })
            if (email !== undefined) {
                this.setUserStatus(UserStatus.Full)
            } else {
                this.setUserStatus(UserStatus.Anonymous)
            }
            const usergameResponse: IUsergameResponse = response2.data
            this.setUsergame(usergameResponse)    
        } catch (e: any) {
            console.log(e.toString())
            console.log(e.stack)
            console.log(e.response?.data?.error)
            if (AuthRequestService.isAuthError(e.response?.data?.error)){
                this.setUserStatus(UserStatus.SigninNeeded)
            } else {
                this.setUserStatus(UserStatus.Error)
            }
            this.setUser(undefined)
            this.setUsergame(undefined)
        } finally {
            this.setLoading(false)
        }
    }

    async signout() {
        try {
            this.setLoading(true)
            const response = await AuthRequestService.signout()
            localStorage.removeItem('session')
            this.setUserStatus(UserStatus.SigninNeeded)
            this.setUser(undefined)
        } catch (e: any) {
            console.log(e.response?.data?.error)
        } finally {
            this.setLoading(false)
        }
    }

    async checkAuth() {
        const session = localStorage.getItem('session')
        if (session !== null) {
            try {              
                this.setLoading(true)  

                const response = await AuthRequestService.check(session)
                console.log("checkAuth, response: " + response.data.session)
                localStorage.setItem('session', response.data.session)
                const user_uuid: string = response.data.user_uuid

                const response2 = await GameRequestService.getUsergame(user_uuid)
                console.log(response2)

                const email: string | undefined = response.data.email
                console.log("email: " + email)
                this.setUser({
                    user_uuid,
                    email
                })
                if (email !== undefined && email !== null) {
                    this.setUserStatus(UserStatus.Full)
                } else {
                    this.setUserStatus(UserStatus.Anonymous)
                }
                const usergameResponse: IUsergameResponse = response2.data
                this.setUsergame(usergameResponse)    
            } catch (e: any) {
                console.log(e.response?.data?.error)
                if (AuthRequestService.isAuthError(e.response?.data?.error)){
                    this.setUserStatus(UserStatus.SigninNeeded)
                } else {
                    this.setUserStatus(UserStatus.Error)
                }
                this.setUser(undefined)
                this.setUsergame(undefined)
            } finally {
                this.setLoading(false)
            }
        } else {
            console.log('Token not found')
            this.setUserStatus(UserStatus.New)
            this.setUser(undefined)
            this.setUsergame(undefined)
        }
    }

    /* async getUsergame() {
        try {
            this.setLoading(true)
            const user_uuid: string = this.user!.user_uuid
            const response = await GameRequestService.getUsergame(user_uuid)
            console.log(response)
            const usergameResponse: IUsergameResponse = response.data
            this.setUsergame(usergameResponse)    
        } catch (e: any) {
            console.log(e.response?.data?.error)
        } finally {
            this.setLoading(false)
        }
    } */
}
