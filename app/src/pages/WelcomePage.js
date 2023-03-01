import React, {useContext} from 'react';
import {Link, useNavigate} from "react-router-dom";
import cl from './WelcomePage.module.css';
import {Context} from "../index";

export default function WelcomePage() {
    let navigate = useNavigate();
    const {store} = useContext(Context);
    return (
        <div className={cl.page}>
            <img src='./img/img/logo.png'/>
            <ul>
                <li>Complete game tasks!</li>
                <li>Exchange cards with friends!</li>
                <li>Get NFT with your favorite team!</li>
            </ul>
            <button className={cl.playButton} autoFocus={true} onClick={
                () => {
                    store.signup() // Anonymous start 
                    navigate('/')
                }
            }>
                Play
            </button>
            {/* <div className={cl.container}>
                <Link to="/signin" className={cl.link}>Sign In</Link>
                <Link to="/signup" className={cl.link}>Sign Up</Link>
            </div> */}
        </div>
    );
}