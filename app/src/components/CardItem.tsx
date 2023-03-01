import {observer} from "mobx-react-lite"
import cl from "./CardItem.module.css" 
import GameViewService from "../services/GameViewService";
import CommonService from "../services/CommonService";

export interface ICardItemProps{
    itemSize: number
    suit: number
    activity?: boolean
    shift?: boolean
}

export const CardItem = (CardItemProps: ICardItemProps) => {
    return (
        <div className={cl.cardItem} style={{
            width: CardItemProps.itemSize + 'px',
            height: CardItemProps.itemSize + 'px',
            marginLeft: (CardItemProps.shift ? ((-CommonService.getCssVarNum('--shift-ratio')*CardItemProps.itemSize) + 'px') : '0px'),
        }}>
            <img 
                className={cl.cardImg} 
                src={GameViewService.getImagePath(
                    CardItemProps.suit, 
                    CardItemProps.activity ?? true
                )}
            />
        </div>
    )
}

export default observer(CardItem)