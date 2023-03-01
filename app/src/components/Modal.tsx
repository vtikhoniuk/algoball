import React, {useContext} from 'react'
import {observer} from "mobx-react-lite"
import cl from './Modal.module.css'
import {Context} from "../index"

export interface IModalProps{
    isWin: boolean,
    visible: boolean
}

const Modal = (modalProps: IModalProps) => {

    const {store} = useContext(Context)

    const rootClasses = [cl.modal]
    if (modalProps.visible) {
        rootClasses.push(cl.active)
    }

    return (
        <div className={rootClasses.join(' ')} 
            onClick={(e) => e.stopPropagation()}
            /* onClick={() => modalProps.setVisible(false)} */
        >
            <div className={cl.modalContent+' '+cl.unselectable}>
                <div className={cl.text}>
                    {modalProps.isWin ? 'You win!' : 'Try again!'}
                </div>
                <button className={cl.button} onClick={() => 
                    modalProps.isWin ? store.nextLevel() : store.checkAuth()
                }>
                    OK
                </button>
            </div>
        </div>
    );
};

export default observer(Modal)