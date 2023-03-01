import cl from './GamePage.module.css'
import React, {useContext, useState, useLayoutEffect, useRef, useEffect} from "react"
import useWindowSize from '../hooks/useWindowSize'
import {Context} from "../index"
import {observer} from "mobx-react-lite"
import Card from '../components/Card'
import Offer from '../components/Offer'
import Modal, {IModalProps} from '../components/Modal'
import CommonService from '../services/CommonService'
import GameService from '../services/GameRequestService'
import GameViewService from '../services/GameViewService'
import GameLayoutService, { IOfferCount, IGameLayout } from '../services/GameLayoutService'
import {UserStatus} from '../store/store'
import { IOffer } from '../models/IUsergame'

function GamePage() {
    const windowSize = useWindowSize()

    const headerRef = useRef(null)
    const delimiterRef = useRef(null)
    const colSetAreaRef = useRef(null)
    const ownSetAreaRef = useRef(null)
    const offerSetAreaRef = useRef(null)
    const footerRef = useRef(null)

    const {store} = useContext(Context)

    const [modal, setModal] = useState<IModalProps>({
        isWin: false, 
        visible: false
    })

    useEffect(() => {
        if (store.userStatus === UserStatus.Win) {
            setModal({
                isWin: true,
                visible: true
            })
        } else if (store.userStatus === UserStatus.Loss) {
            setModal({
                isWin: false,
                visible: true
            })
        } else {
            setModal({
                isWin: false,
                visible: false
            })
        }
    },[store.userStatus])

    const [gameLayout, setGameLayout] = useState<IGameLayout>({
        rowSize: 0,
        itemSize: 0,
        colRowsCount: 1,
        cardRowsCount: 1,
        offerRowsCount: 1
    })

    useLayoutEffect(() => {
        if (headerRef.current && 
            delimiterRef.current &&
            colSetAreaRef.current && 
            ownSetAreaRef.current &&
            offerSetAreaRef.current &&
            footerRef.current &&
            windowSize.height &&
            windowSize.width
        ){
            const headerHeight = parseFloat(window.getComputedStyle(headerRef.current).height)
            const delimiterHeight = parseFloat(window.getComputedStyle(delimiterRef.current).height)
            const colSetAreaMargin = parseFloat(window.getComputedStyle(colSetAreaRef.current).margin)
            const colSetAreaWidth = parseFloat(window.getComputedStyle(colSetAreaRef.current).width)
            const ownSetAreaMargin = parseFloat(window.getComputedStyle(ownSetAreaRef.current).margin)
            const offerSetAreaMargin = parseFloat(window.getComputedStyle(offerSetAreaRef.current).margin)
            const footerHeight = parseFloat(window.getComputedStyle(footerRef.current).height)

            setGameLayout( 
                GameLayoutService.getGameLayout(
                    (windowSize.height - 
                        headerHeight - 
                        delimiterHeight*3 - 
                        colSetAreaMargin*2 - 
                        ownSetAreaMargin*2 -
                        offerSetAreaMargin*2 -
                        footerHeight
                    ),
                    colSetAreaWidth,
                    CommonService.getCssVarNum('--card-margin-ratio'),
                    CommonService.getCssVarNum('--shift-ratio'),
                    CommonService.getCssVarNum('--offer-padding-ratio'),
                    store.usergame!.colSet.length,
                    store.usergame!.ownSet.length,
                    store.usergame!.offerSet.map((offer:IOffer):IOfferCount => {
                        return {itemCount: offer.itemCount, shiftCount: offer.shiftCount}
                    })
                )
            )            
        }
    }, [windowSize])
    
    return (
        <div className={cl.page}>
            <Modal isWin={modal.isWin} visible={modal.visible} />
            <header ref={headerRef}>
                <div className={cl.container}>
                    <div className={cl.headerArea}>
                        <div>
                            <img className={cl.logo} src='./img/img/logo.png'/>
                        </div>
                        <div className={cl.menuArea}>
                            {/* <p className={cl.menuLink}>
                                Reload
                            </p> */}
                            {/* <p className={cl.menuLink}>
                                Sign In
                            </p> */}
                            <button className={cl.simpleButton} 
                                onClick={() => store.checkAuth()}
                            >
                                <img src='./img/img/reload.png'/>
                            </button>
                            <button className={cl.ctaButton2}> 
                                Mint NFT
                            </button>
                        </div>
                    </div>
                    <div className={cl.lineArea1}>
                        <img src='./img/img/line1.png'/>
                    </div>
                    <div className={cl.lineArea2}>
                        <img src='./img/img/line2.png'/>
                    </div>
                    <div className={cl.scoreArea}>
                        <p>Coins: {store.usergame!.balance}</p>
                        <p>Moves: {store.usergame!.moves}</p>
                        <p>Level: {store.usergame!.level}</p>
                    </div>
                </div>
            </header>
            <main className={cl.main}>
                <div className={cl.container}>
                    <div className={cl.mainArea}>
                        <div className={cl.delimiter} ref={delimiterRef}> 
                            Collection to build
                        </div>
                        <div className={cl.setContainer} ref={colSetAreaRef}>
                            <div className={cl.setArea} style={{
                                height: (
                                    gameLayout.rowSize*gameLayout.colRowsCount +
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.rowSize*
                                    (gameLayout.colRowsCount + 1)
                                ) +'px' ,
                                paddingTop: (
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.itemSize
                                ) +'px',
                                paddingLeft: (
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.itemSize
                                ) +'px'
                            }}>
                                {store.usergame!.colSet.map((card, index) => 
                                    <Card 
                                        key={index} 
                                        suit={card.suit} 
                                        itemSize={gameLayout.itemSize} 
                                        activity={card.activity}
                                    />
                                )}
                            </div>
                        </div>
                        <div className={cl.delimiter}> 
                            Own cards 
                        </div>
                        <div className={cl.setContainer} ref={ownSetAreaRef}>
                            <div className={cl.setArea} style={{
                                height: (
                                    gameLayout.rowSize*gameLayout.cardRowsCount +
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.rowSize*
                                    (gameLayout.cardRowsCount + 1)
                                ) + 'px',
                                paddingTop: (
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.itemSize
                                ) +'px',
                                paddingLeft: (
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.itemSize
                                ) +'px'
                            }}>
                                {store.usergame!.ownSet.map((card, index) => 
                                    <Card 
                                        key={index} 
                                        suit={card.suit} 
                                        itemSize={gameLayout.itemSize} 
                                        activity={card.activity}
                                    />
                                )}
                            </div>
                        </div>
                        <div className={cl.delimiter}> 
                            Exchange options
                        </div>
                        <div className={cl.setContainer} ref={offerSetAreaRef}>
                            <div className={cl.setArea} style={{
                                height: (
                                    gameLayout.rowSize*gameLayout.offerRowsCount + 
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.rowSize*
                                    (gameLayout.offerRowsCount + 1) +
                                    CommonService.getCssVarNum('--offer-padding-ratio')*
                                    gameLayout.rowSize*
                                    gameLayout.offerRowsCount*2
                                ) + 'px',
                                paddingTop: (
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.itemSize
                                ) +'px',
                                paddingLeft: (
                                    CommonService.getCssVarNum('--card-margin-ratio')*
                                    gameLayout.itemSize
                                ) +'px'
                            }}>
                                {store.usergame!.offerSet.map((offer, index) => 
                                    <Offer 
                                        key={index} 
                                        index={index} 
                                        offer={offer} 
                                        itemSize={gameLayout.itemSize} 
                                        activity={offer.activity}
                                    />
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </main>
            <footer ref={footerRef}>
                <div className={cl.container}>
                    <div className={cl.footerLineArea}>
                        {/* <img src='./img/img/line1.png'/> */}
                    </div>
                    {/*<div className={cl.footerArea}>
                        <button className={cl.footerButton}>Game</button>
                        <button className={cl.footerButton}>Market</button>
                        <button className={cl.footerButton}>Friends</button>
                        <button className={cl.footerButton}>NFT</button>
                    </div> */}
                </div>
            </footer>
        </div>
    )
}

export default observer(GamePage)