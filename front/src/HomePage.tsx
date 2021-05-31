import * as React from 'react'
import './HomePage.scss'
import { Link } from 'react-router-dom'

interface HomePageProps {
  setAppState: Function
}

interface HomePageState {
}

class HomePage extends React.Component<HomePageProps, HomePageState> {
  handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const target = event.target
    const value = target.value
    const name = target.name

    this.setState((prevState) => ({
      ...prevState,
      [name]: value
    }))
  }

  public render() {
    return (
      <div className="container">
        <div className="text-center waiting-list-title">
          <h1>Notes about books, podcasts, ideas, etc.</h1>
          <div>Writing is thinking. Note-taking fosters writing. In the open.</div>
        </div>
        <div className="row">
          <div className="col-lg-4"></div>
          <div className="col-lg-4 center">
            <div className="center-buttons">
              <Link to="/login" className="btn btn-primary" onClick={() => window.location.href = `/login`}>Log in</Link>
            </div>
          </div>
          <div className="col-lg-4"></div>
        </div>
      </div>
    )
  }
}

export default HomePage
