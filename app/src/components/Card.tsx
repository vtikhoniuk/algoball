import {observer} from "mobx-react-lite"
import cl from "./Card.module.css" 
import CommonService from "../services/CommonService";
import CardItem from "./CardItem"

export interface ICardProps{
    itemSize: number
    suit: number
    activity?: boolean
}

const Card = (CardProps: ICardProps) => {
    return (
        <div className={cl.cardContainer}             
            style={{
                marginRight: (CommonService.getCssVarNum('--card-margin-ratio')*CardProps.itemSize) + 'px', 
                marginBottom: (CommonService.getCssVarNum('--card-margin-ratio')*CardProps.itemSize) + 'px',
            }} 
        >
            <CardItem 
                suit={CardProps.suit} 
                itemSize={CardProps.itemSize}
                activity={CardProps.activity}
            />
        </div>
    )
}

export default observer(Card)