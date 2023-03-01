import {useContext, useEffect} from 'react'
import {Routes, Route, Navigate} from "react-router-dom"
import {observer} from "mobx-react-lite"
import WelcomePage from './pages/WelcomePage'
import SigninPage from './pages/SigninPage'
import SignupPage from './pages/SignupPage'
import GamePage from './pages/GamePage'
import {Context} from "./index"
import {UserStatus} from './store/store'

//function Onboarding({ children }: { children: JSX.Element }) {
const Onboarding = observer(({ children }: { children: JSX.Element }) => {    
    const {store} = useContext(Context)
    
    console.log('Onboarding status -> ' + UserStatus[store.userStatus])
    if (store.userStatus === UserStatus.New) {
        return <Navigate to ="/welcome"/>
    } else if (store.userStatus === UserStatus.SigninNeeded) {
        return <Navigate to ="/signin"/>
    } else {
        return children
    }
})

function App() {
    const {store} = useContext(Context);

    useEffect(() => {
        store.checkAuth()
    }, [])

    if (store.isLoading || store.userStatus === UserStatus.Undefined) {
        return <div>Loading...</div>
    }

    if (store.userStatus === UserStatus.Error) {
        return(
            <div>
                Error...
                Try connect later
            </div>
        )
    }

    return(
        <Routes>
            <Route path="/" 
                element={
                    <Onboarding>
                        <GamePage/>
                    </Onboarding>
                } 
            /> {/* Todo: add layout and child pages (nft, market etc.) */}
            <Route path="/signin" element={<SigninPage/>} />
            <Route path="/signup" element={<SignupPage/>} />
            <Route path="/welcome" element={<WelcomePage/>} />
        </Routes>
    )
}

export default observer(App)