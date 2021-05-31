import * as React from 'react'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'
import { apiDomain } from './appConfig'
import { Link } from 'react-router-dom'
import { recaptchaRef, recaptchaEnabled } from './utils/recaptcha'
import { backendErrorsToMessage } from './backendSync'

interface LoginProps {
  setParentState: Function
}

interface LoginState {
  email: string
  password: string
  error: string
}

class Login extends React.Component<LoginProps, LoginState> {
  constructor(props: LoginProps) {
    super(props)

    this.state = {
      email: "",
      password: "",
      error: ""
    }
  }

  handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const target = event.target
    const value = target.value
    const name = target.name

    this.setState((prevState) => ({
      ...prevState,
      [name]: value
    }))
  }

  submit = async () => {
    const current = recaptchaRef.current
    const token = recaptchaEnabled && current ? await current.executeAsync() : ""

    const { email, password } = this.state
    const args = {
      email: email,
      password: password,
      "g-recaptcha-response": token
    }
    // axios.defaults.withCredentials = true
    axios.post(apiDomain() + "/v1/users/login", args, { headers: { 'Content-Type': 'application/json', "Accept": "application/json" }, withCredentials: true })
      .then(_ => {
        window.location.href = '/'
      })
      .catch(error => {
        let msg = ""
        if (error.response && error.response.data) {
          msg = backendErrorsToMessage(error)
        } else {
          msg = "There was an error. Try again later."
        }
        this.props.setParentState({ alert: { variant: "danger", message: msg } })
      })
  }
  public render() {
    const { email, password, error } = this.state

    return(
      <div className="container">
        <div className="row">
          <div className="col-lg-4"></div>
          <div className="col-lg-4">
            {error}
            <Form>
              <Form.Group>
                <Form.Label>Email</Form.Label>
                <Form.Control
                  type="text"
                  value={email}
                  name="email"
                  onChange={this.handleChange as any} autoFocus />
              </Form.Group>

              <Form.Group>
                <Form.Label>Password</Form.Label>
                <Form.Control
                  type="password"
                  value={password}
                  name="password"
                  onChange={this.handleChange as any}
                  autoComplete="current-password" />
              </Form.Group>

              <Button onClick={this.submit}>Login</Button>
            </Form>
          </div>
          <div className="col-lg-4"></div>
        </div>
      </div>
    )
  }
}

export default Login;
