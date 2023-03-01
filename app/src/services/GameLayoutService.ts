export interface IOfferCount{
    itemCount: number,
    shiftCount: number
}

export interface IGameLayout{
    rowSize: number,
    itemSize: number,
    colRowsCount: number,
    cardRowsCount: number,
    offerRowsCount: number
}

export default class GameLayoutService{
    
    static getTotalWidth(
        widthSet: number[],
        marginRatio: number,
        paddingRatio: number
    ): number {
        let setWidth: number = 0
        widthSet.forEach((value: number) => 
            setWidth += value + 2*paddingRatio + marginRatio
        )
        return setWidth - marginRatio
    }

    static getMinRowWidth(
        widthSet: number[],
        marginRatio: number,
        paddingRatio: number,
        rows: number
    ): number {
        const totalWidth: number = this.getTotalWidth(widthSet, marginRatio, paddingRatio)
        if (rows === 1 || widthSet.length === 1) {
            return totalWidth
            
        } else {
            let bestMinWidth: number = totalWidth
            let currentWidth: number = 0
            let index: number = 1
            while (index < widthSet.length) {
                currentWidth = Math.max(
                    this.getTotalWidth(
                        widthSet.slice(0, index),
                        marginRatio,
                        paddingRatio
                    ),
                    this.getMinRowWidth(
                        widthSet.slice(index),
                        marginRatio,
                        paddingRatio,
                        rows-1
                    )
                )
                if (bestMinWidth > currentWidth){
                    bestMinWidth = currentWidth
                }
                index++
            }
            return bestMinWidth
        }
    }

    static getGameLayout(
        height: number, // available height
        width: number, // available widht
        itemMarginRatio: number, // itemMargin/itemSize
        shiftRatio: number, // shiftMargin/itemSize
        offerPaddingRatio: number, // offerPadding/itemSize
        colCount: number,
        cardCount: number,
        offerSet: IOfferCount[]
    ): IGameLayout {

        /* console.log("Params:" + height + ", " + width + ", " + 
            itemMarginRatio + ", " + shiftRatio + ", " + offerPaddingRatio + ", " + 
            colCount + ", " + cardCount + ", " + JSON.stringify(offerSet)
        ) */

        let colRows: number = 1
        let cardRows: number = 1
        let offerRows: number = 1
        let itemSize: number = 0
        let itemSizeFromHeight: number = 0
        let nextItemSize: number = 0
        let rowCountCalculated: boolean = false

        while (!rowCountCalculated) {
            rowCountCalculated = true

            let offerRowItemCount = this.getMinRowWidth(
                offerSet.map((offer: IOfferCount) => 
                    (offer.itemCount - offer.shiftCount*shiftRatio)
                ),
                itemMarginRatio,
                offerPaddingRatio,
                offerRows
            )

            let itemSizeFromCol = width/(
                Math.ceil(colCount/colRows) + 
                itemMarginRatio*(Math.ceil(colCount/colRows) + 1)
            )
            let itemSizeFromCard = width/(
                Math.ceil(cardCount/cardRows) +
                itemMarginRatio*(Math.ceil(cardCount/cardRows) + 1)
            )
            let itemSizeFromOffer = width/(
                offerRowItemCount +
                itemMarginRatio*2
            )
            itemSizeFromHeight = height/( 
                colRows + cardRows + offerRows +
                itemMarginRatio*(colRows + cardRows + offerRows + 3) + 
                offerPaddingRatio*2*offerRows
            )

            itemSize = Math.min(
                itemSizeFromCol,
                itemSizeFromCard,
                itemSizeFromOffer,
                itemSizeFromHeight
            )

            let horMinItemSize = Math.min(
                itemSizeFromCol,
                itemSizeFromCard,
                itemSizeFromOffer
            )

            let nextItemRowModificator: number = 0
            if (itemSizeFromCol === itemSizeFromCard &&
                itemSizeFromCard === itemSizeFromOffer
            ){
                if (colCount > colRows &&   
                    cardCount > cardRows &&
                    offerSet.length > offerRows
                ){
                    nextItemRowModificator = 3
                }
            } else if (itemSizeFromCol === itemSizeFromCard && 
                       itemSizeFromCol === horMinItemSize
            ){
                if (colCount > colRows &&
                    cardCount > cardRows
                ){
                    nextItemRowModificator = 2
                }
            } else if (itemSizeFromCard === itemSizeFromOffer && 
                       itemSizeFromCard === horMinItemSize
            ){
                if (cardCount > cardRows &&
                    offerSet.length > offerRows
                ){
                    nextItemRowModificator = 2
                }
            } else if (itemSizeFromCol === itemSizeFromOffer && 
                       itemSizeFromCol === horMinItemSize
            ){
                if (cardCount > cardRows &&
                    offerSet.length > offerRows
                ){
                    nextItemRowModificator = 2
                }
            } else if (itemSizeFromCol === horMinItemSize){
                if (colCount > colRows){
                    nextItemRowModificator = 1
                }
            } else if (itemSizeFromCard === horMinItemSize){
                if (cardCount > cardRows){
                    nextItemRowModificator = 1
                }
            } else if (itemSizeFromOffer=== horMinItemSize){
                if (offerSet.length > offerRows){
                    nextItemRowModificator = 1
                }
            }
                
            let nextItemOfferModificator: number = 0
            if (itemSizeFromOffer === horMinItemSize &&
                offerSet.length > offerRows
            ){
                nextItemOfferModificator = 1
            } 

            nextItemSize = height/( 
                colRows + cardRows + offerRows + nextItemRowModificator +
                itemMarginRatio*(colRows + cardRows + offerRows + 3 + nextItemRowModificator) + 
                offerPaddingRatio*2*(offerRows + nextItemOfferModificator)
            )

            /* console.log('colRows exp: ' + itemSizeFromCol)
            console.log('cardRows exp: ' + itemSizeFromCard)
            console.log('offerRows exp: ' + itemSizeFromOffer)
            console.log('height exp: ' + itemSizeFromHeight)
            console.log('nextItemRowModificator: ' + nextItemRowModificator)
            console.log('nextItemOfferModificator: ' + nextItemOfferModificator)
            console.log("itemSize = " + itemSize)
            console.log("nextItemSize = " + nextItemSize) */
            
            if ((itemSizeFromCol === itemSize) &&
                (width < nextItemSize*Math.ceil(colCount/colRows) + nextItemSize*itemMarginRatio*(Math.ceil(colCount/colRows)+1)) &&
                colCount > colRows &&
                nextItemRowModificator > 0
            ){
                colRows++
                rowCountCalculated = false
            }

            if ((itemSizeFromCard === itemSize) &&
                (width < nextItemSize*Math.ceil(cardCount/cardRows) + nextItemSize*itemMarginRatio*(Math.ceil(cardCount/cardRows)+1)) &&
                cardCount > cardRows &&
                nextItemRowModificator > 0
            ){
                cardRows++
                rowCountCalculated = false
            }
            
            if ((itemSizeFromOffer === itemSize) && 
                (width < nextItemSize*(offerRowItemCount + 2*itemMarginRatio)) &&
                offerSet.length > offerRows &&
                nextItemRowModificator > 0 &&
                nextItemOfferModificator > 0
            ){
                offerRows++
                rowCountCalculated = false
            }
        }

        return {
            rowSize: itemSizeFromHeight,
            itemSize: itemSize,
            colRowsCount: colRows,
            cardRowsCount: cardRows,
            offerRowsCount: offerRows
        } as IGameLayout
    }
}