import * as React from 'react'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'
import { apiDomain } from './appConfig'
import { Link } from 'react-router-dom'
import { backendErrorsToMessage } from './backendSync'
import { recaptchaRef, recaptchaEnabled } from './utils/recaptcha'

interface SignUpProps {
  setAppState: Function
}

interface SignUpState {
  email: string
  password: string
  name: string
  username: string
  marketing: boolean
}

class SignUp extends React.Component<SignUpProps, SignUpState> {
  constructor(props: SignUpProps) {
    super(props)

    this.state = {
      email: "",
      password: "",
      name: "",
      username: "",
      marketing: false
    }
  }

  handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const target = event.target
    const name = target.name
    const value = target.type === 'checkbox' ? target.checked : target.value

    this.setState((prevState) => ({
      ...prevState,
      [name]: value
    }))
  }

  signup = async () => {
    const { email, password, name, username, marketing } = this.state
    const current = recaptchaRef.current
    const token = recaptchaEnabled && current ? await current.executeAsync() : ""
    const args = {
      email: email,
      password: password,
      name: name,
      username: username,
      marketing: marketing,
      "g-recaptcha-response": token
    }

    axios.post(apiDomain() + "/v1/users", args, { headers: { 'Content-Type': 'application/json', "Accept": "application/json" }, withCredentials: true })
      .then(res => {
        window.location.href = "/help"
      })
      .catch(error => {
        if (error.response.status === 401) {
          this.props.setAppState({ alert: { message: "Are you human? If so, please refresh and try again.", variant: "danger" } })
        } else {
          this.props.setAppState({ alert: { message: backendErrorsToMessage(error), variant: "danger" } })
        }
      })
  }

  public render() {
    const { email, password, name, username } = this.state

    return (
      <div className="container">
        <div className="row">
          <div className="col-lg-4"></div>
          <div className="col-lg-4">
            <Form>
              <Form.Group>
                <Form.Label>Enter your name:</Form.Label>
                <Form.Control
                  type="text"
                  value={name}
                  name="name"
                  onChange={this.handleChange as any} autoFocus />
              </Form.Group>

              <Form.Group>
                <Form.Label>Email:</Form.Label>
                <Form.Control
                  type="text"
                  value={email}
                  name="email"
                  onChange={this.handleChange as any} />
              </Form.Group>

              <Form.Group>
                <Form.Label>Choose a username:</Form.Label>
                <Form.Control
                  type="text"
                  value={username}
                  name="username"
                  onChange={this.handleChange as any} />
              </Form.Group>

              <Form.Group>
                <Form.Label>Choose a password:</Form.Label>
                <Form.Control
                  type="password"
                  value={password}
                  name="password"
                  onChange={this.handleChange as any}
                  autoComplete="new-password" />
              </Form.Group>

              <Form.Group controlId="termsAndConditions">
                <Form.Check
                  type="checkbox"
                  label="Join the Notes Club newsletter."
                  onChange={this.handleChange as any}
                  name="marketing" />
              </Form.Group>
              <p className="small">By clicking on Join, you agree to our <Link to="/terms">terms</Link> and <Link to="/privacy">privacy</Link> conditions.</p>
              <Button onClick={this.signup}>Sign up</Button>
            </Form>
          </div>
          <div className="col-lg-4"></div>
        </div>
      </div>
    )
  }
}

export default SignUp
