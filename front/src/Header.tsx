import * as React from 'react'
import { Navbar, Nav } from 'react-bootstrap'
import { User } from './User'
import Search from './Search'

interface HeaderProps {
  setParentState: Function
  currentUser?: User | null
}

interface HeaderState {

}

class Header extends React.Component<HeaderProps, HeaderState> {
  renderLoggedInHeader = () => {
    const { currentUser } = this.props

    return(
      currentUser && this.renderHeader()
    )
  }

  renderHeader = () => {
    const { currentUser } = this.props
    return (
      <>
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="mr-auto">
          </Nav>
          {currentUser &&
            <Search currentUser={currentUser} />
          }
          <Nav.Link href='/books'>Books</Nav.Link>
          {currentUser && currentUser.name !== "Help" &&
            <Nav.Link href="/help">Help</Nav.Link>
          }
          {currentUser &&
            <Nav.Link href={`/${currentUser.username}`}>{(currentUser.name || currentUser.username)}</Nav.Link>
          }
          <Nav.Link href='/logout'>Logout</Nav.Link>
        </Navbar.Collapse>
      </>
    )
  }

  renderAnonymousHeader = () => {
    return (
      <>
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="mr-auto">
          </Nav>
          <Nav.Link href='/login' onClick={() => window.location.href='/login'}>Log in</Nav.Link>
        </Navbar.Collapse>
      </>
    )
  }

  public render() {
    const { currentUser } = this.props

    return (
      <Navbar bg="light" expand="lg">
        <Navbar.Brand href="/">Notes Club</Navbar.Brand>
        {currentUser ? this.renderLoggedInHeader() : this.renderAnonymousHeader()}
      </Navbar>
    )
  }
}

export default Header;
