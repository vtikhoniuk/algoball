import {useContext} from "react"
import {observer} from "mobx-react-lite"
import cl from "./Offer.module.css" 
import {IOffer } from "../models/IUsergame";
import CardItem from "./CardItem"
import {Context, store} from "../index"
import CommonService from "../services/CommonService";
import { button } from "./Modal.module.css";

export interface IOfferProps{
    itemSize: number
    offer: IOffer
    key: number
    index: number
    activity?: boolean
}

const Offer = (OfferProps: IOfferProps) => {
    const {store} = useContext(Context)

    return (
        <button className={cl.offerContainer} disabled={!OfferProps.activity} 
            style={{
                padding: (CommonService.getCssVarNum('--offer-padding-ratio')*OfferProps.itemSize) + 'px',
                marginRight: (CommonService.getCssVarNum('--card-margin-ratio')*OfferProps.itemSize) + 'px', 
                marginBottom: (CommonService.getCssVarNum('--card-margin-ratio')*OfferProps.itemSize) + 'px',
            }} 
            onClick={() => {
                store.applyOffer(OfferProps.index)
            }}
        >
            {OfferProps.offer.originalSet.map((card, index) => 
                <CardItem 
                    key={index} 
                    suit={card.suit} 
                    itemSize={OfferProps.itemSize}
                    shift={card.shift}
                    activity={OfferProps.activity}
                />
            )}
            <CardItem 
                key={0} 
                suit={99011} 
                itemSize={OfferProps.itemSize}
                shift={OfferProps.offer.arrowShift}
                activity={OfferProps.activity}
            />
            {OfferProps.offer.flipSet.map((card, index) => 
                <CardItem 
                    key={index} 
                    suit={card.suit} 
                    itemSize={OfferProps.itemSize}
                    shift={card.shift}
                    activity={OfferProps.activity}
                />
            )}
        </button>
    )
}

export default observer(Offer)