import {createContext} from 'react';
import {createRoot} from 'react-dom/client';
import {BrowserRouter} from "react-router-dom";
import App from './App';
import './css/index.css';
import Store, {IStore} from "./store/store";

export const store = new Store();

export const Context = createContext<IStore>({store})

const rootElement = document.getElementById('root');
const root = createRoot(rootElement!); 
root.render(
    //<React.StrictMode>
        <BrowserRouter>
            <Context.Provider value={{store}}>
                <App />
            </Context.Provider>
        </BrowserRouter>
    //</React.StrictMode>
);  