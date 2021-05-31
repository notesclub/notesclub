import * as React from 'react'
import { Link } from 'react-router-dom'

class LoginOrSignup extends React.Component {
  render() {
    return (
      <div>
        <Link to="/login" onClick={() => window.location.href = "/login"}>Log in</Link>
        {" to add notes."}
      </div>
    )
  }
}

export default LoginOrSignup
