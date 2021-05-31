import * as React from 'react';
import './App.scss';
import '@ionic/react/css/core.css';
import Login from './Login';
import Logout from './Logout';
import Header from './Header';
import { Alert } from 'react-bootstrap';
import { BrowserRouter as Router, Switch, Route, Redirect } from 'react-router-dom'
import UserNotePage from './notes/UserNotePage'
import UserPage from './UserPage'
import BooksPage from './BooksPage'
import Feed from './Feed'
import HomePage from './HomePage'
import SignUp from './SignUp'
import { User } from './User'
import { fetchAuthenticatedUser } from './backendSync'
import ConfirmationToken from './ConfirmationToken'
import Privacy from './Privacy'
import Terms from './Terms'
import NewBookPage from './NewBookPage'

interface AppProps {

}

interface alert {
  variant: "primary" | "secondary" | "success" | "danger" | "warning" | "info" | "dark" | "light"
  message: string
}

interface AppState {
  currentUser?: User | null
  alert?: alert
}

class App extends React.Component<AppProps, AppState> {
  constructor(props: AppProps) {
    super(props)

    this.state = {
      alert: undefined,
    }
  }

  componentDidMount() {
    const { currentUser } = this.state

    if (currentUser === undefined) {
      fetchAuthenticatedUser()
        .then(currentUser => {
          this.setState({ currentUser: currentUser === undefined ? null : currentUser })
        })
        .catch(error => {
          if (error && error.response && error.response.status === 401) {
            this.setState({ currentUser: null })
          } else {
            this.setState({ currentUser: null, alert: { message: "Sync error. Please try again later. Sorry, we're in alpha!", variant: "danger" } })
          }
        })
    }
  }

  updateAlert = (variant: "primary" | "secondary" | "success" | "danger" | "warning" | "info" | "dark" | "light", message: string) => {
    this.setState({ alert: { variant: variant, message: message } })
  }

  updateState = (partialState: Partial<AppState>) => {
    const newState: AppState = { ...this.state, ...partialState };
    this.setState(newState);
  }

  renderRoutes = () => {
    const { currentUser } = this.state

    return (
      <Switch>
        <Route path="/privacy" exact render={() => <Privacy />} />
        <Route path="/terms" exact render={() => <Terms />} />
        <Route path="/logout" exact render={() => <Logout />} />
        <Route path="/login" exact render={() => <Login setParentState={this.updateState} />} />
        <Route path="/users/confirmation/:token" exact render={({ match }) => <ConfirmationToken token={match.params.token} setAppState={this.updateState} />} />
        <Route path="/books" exact render={({ match }) => <BooksPage currentUser={currentUser} setAppState={this.updateState} />} />
        {currentUser ?
          <Route path="/books/new" exact render={({ match }) => <NewBookPage currentUser={currentUser} setAppState={this.updateState} />} />
        :
          <Route path="/books/new" exact>
            {currentUser === null ? <Login setParentState={this.updateState} /> : <div className="container">Loading...</div>}
          </Route>
        }
        {currentUser === null &&
          <Redirect path="/notes/:noteKey" exact to="/login" />
        }
        <Route path="/:blogUsername/:noteKey" exact render={({ match }) => <UserNotePage currentBlogUsername={match.params.blogUsername} currentNoteKey={match.params.noteKey} currentUser={currentUser} setAppState={this.updateState} />} />
        <Route path="/:blogUsername" exact render={({ match }) => <UserPage currentUser={currentUser} blogUsername={match.params.blogUsername} setAppState={this.updateState} />} />
        {currentUser &&
          <Switch>
            <Route path="/" exact render={({ match }) => <Feed currentUser={currentUser} blogUsername={match.params.blogUsername} setAppState={this.updateState} />} />
          </Switch>
        }
        {currentUser === undefined &&
          <Switch>
            <Route path="/" exact render={() => <div className="container">Loading</div>} />
          </Switch>
        }
        {currentUser === null &&
          <Switch>
            <Route path="/" exact render={() => <HomePage setAppState={this.updateState} />} />
            <Route path="/signup" exact render={() => <SignUp setAppState={this.updateState} />} />
            <Route path="/:whatever" exact>
              {<Login setParentState={this.updateState} />}
            </Route>
            <Route path="/:whatever/:something" exact>
              {<Login setParentState={this.updateState} />}
            </Route>
          </Switch>
        }
      </Switch>
    )
  }

  public render() {
    const { alert, currentUser } = this.state

    return (
      <div className="App">
        <Router>
          <Header setParentState={this.updateState} currentUser={currentUser} />
          <div className="text-center">
            {alert ? <Alert variant={alert["variant"]} onClose={() => this.updateState({alert: undefined})} dismissible>{alert["message"]}</Alert> : <></>}
          </div>
          {this.renderRoutes()}
        </Router>
      </div>
    )
  }
}

export default App
