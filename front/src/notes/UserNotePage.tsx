import * as React from 'react'
import { withRouter, RouteComponentProps } from 'react-router-dom'
import queryString from 'query-string'
import { Note, Reference, newNoteWithDescendants, noteKey, newNote, NoteWithFamily, sameNote } from './Note'
import NoteRenderer from './NoteRenderer'
import CurrentNoteContentRenderer from './CurrentNoteContentRenderer'
import { User } from './../User'
import { fetchBackendUser, fetchBackendNotes, createBackendNote } from './../backendSync'
import { getChildren } from './ancestry'
import { Link } from 'react-router-dom'
import ReferenceRenderer from './ReferenceRenderer'
import LoginOrSignup from '../LoginOrSignup'
import axios from 'axios'
import { apiDomain } from './../appConfig'
import './UserNotePage.scss'

interface UserNotePageProps extends RouteComponentProps<any> {
  setAppState: Function
  currentUser?: User | null
  currentNoteKey: string
  currentBlogUsername: string
}

interface UserNotePageState {
  currentBlogger?: User | null
  currentNote?: Note | null
  selectedNote: Note | null
  descendants?: Note[]
  ancestors?: Note[]
  references?: Reference[]
  synced: boolean
}

interface NewDescendantsByTmpKey {
  [key: string]: number
}

interface StateArgsToUpdate {
  descendants: Note[]
  selectedNote?: Note
}

class UserNotePage extends React.Component<UserNotePageProps, UserNotePageState> {
  private timerId?: ReturnType<typeof setTimeout>

  constructor(props: UserNotePageProps) {
    super(props)

    this.state = {
      selectedNote: null,
      synced: true
    }
  }

  componentDidMount() {
    this.timerId = setInterval(() => this.sync(), 2000)
  }

  componentWillUnmount() {
    if (this.timerId) {
      clearInterval(this.timerId)
    }
  }

  sync = () => {
    const { synced, currentNote } = this.state

    if (!synced && currentNote) {
      this.setState({ synced: true })
      this.syncNoteAndDescendants()
    }
  }

  syncNoteAndDescendants = () => {
    const { currentNote, descendants } = this.state

    if (currentNote) {
      const args = {
        note: currentNote,
        update_notes_with_links: true,
        descendants: descendants
      }

      axios.put(apiDomain() + `/v1/notes/${currentNote.id}`, args, { headers: { 'Content-Type': 'application/json', "Accept": "application/json" }, withCredentials: true })
        .then(res => {
          this.changeSlugIfItExisted(res.data as Note)
          this.setIdsForNewDescendants(res.data)
        })
    }
  }

  changeSlugIfItExisted = (note: Note) => {
    let { currentNote } = this.state
    if (note.slug && currentNote && note.slug !== currentNote.slug) {
      this.props.history.push(note.slug)
      currentNote.slug = note.slug
      this.setState({ currentNote: currentNote })
    }
  }

  setIdsForNewDescendants = (noteWithDescendants: NoteWithFamily) => {
    const newDescendants = noteWithDescendants.descendants
    let { descendants, selectedNote } = this.state
    if (newDescendants && descendants) {
      let newDescendantsByTmpKey: NewDescendantsByTmpKey = {}
      newDescendants.forEach((descendant) => {
        if (descendant.tmp_key && descendant.id) {
          newDescendantsByTmpKey[descendant.tmp_key] = descendant.id
        }
      })
      descendants = descendants.map((descendant) => {
        if (!descendant.id && descendant.tmp_key && newDescendantsByTmpKey[descendant.tmp_key]) {
          descendant.id = newDescendantsByTmpKey[descendant.tmp_key]
        }
        return (descendant)
      })
      if (selectedNote && !selectedNote.id && selectedNote.tmp_key) {
        let selectedNoteUpdatedId = newDescendantsByTmpKey[selectedNote.tmp_key]
        if (!selectedNoteUpdatedId && (noteWithDescendants.tmp_key === selectedNote.tmp_key) && noteWithDescendants.id) {
          selectedNoteUpdatedId = noteWithDescendants.id
        }
        if (selectedNoteUpdatedId) {
          selectedNote.id = selectedNoteUpdatedId
          this.setState({ descendants: descendants, selectedNote: selectedNote })
        } else {
          this.setState({ descendants: descendants })
        }
      } else {
        this.setState({ descendants: descendants })
      }
    }
  }

  redirectToUserNote = (username: string) => {
    const { currentNoteKey } = this.props
    // This is used by Wikir's Chrome Extension so it can redirect to a note without knowing the username
    // We should use history.push or replace, but I couldn't make it work. Although I didn't spend much time.
    const params = queryString.parse(this.props.location.search)
    if (params["content"]) {
      window.location.href = `/${username}/${currentNoteKey}?content=${params["content"]}`
    } else {
      window.location.href = `/${username}/${currentNoteKey}`
    }
  }

  fetchBloggerAndCurrentNote = () => {
    const { currentBlogUsername, currentUser, currentNoteKey } = this.props

    fetchBackendUser(currentBlogUsername)
      .then(blogger => {
        this.setState({ currentBlogger: blogger === undefined ? null : blogger})
        if (blogger) {
          fetchBackendNotes({ slug: currentNoteKey, user_ids: [blogger.id], include_descendants: true, include_ancestors: true }, this.props.setAppState)
            .then(fetchBackendNotesAndDescendants => {
              const isOwnBlog = currentUser ? currentUser.id === blogger.id : false
              if (fetchBackendNotesAndDescendants.length === 0) {
                // Create note
                if (isOwnBlog && currentUser) {
                  const params = queryString.parse(this.props.location.search)
                  const newNonSavedNote = newNote({
                    slug: currentNoteKey,
                    user_id: currentUser.id,
                    ancestry: null,
                    position: -1, // We'll replace this with null before sending it to the backend so it adds it to the end
                    content: params["content"] ? String(params["content"]) : undefined
                  })
                  const args = { note: newNonSavedNote, setAppState: this.props.setAppState, include_ancestors: true, include_descendants: true }
                  createBackendNote(args)
                    .then(note => {
                      this.props.history.push(`/${currentUser.username}/${currentNoteKey}`) // get rid of the content argument
                      this.setNoteAndCreateDescendantIfNone(note, isOwnBlog)
                    })
                } else {
                  this.setState({ currentNote: null })
                  this.setReferences()
                }
              } else {
                // Note already exists
                this.setNoteAndCreateDescendantIfNone(fetchBackendNotesAndDescendants[0], isOwnBlog)
              }
            })
        }
      })
  }

  setNoteAndCreateDescendantIfNone = (noteAndFamily: NoteWithFamily, isOwnBlog: boolean) => {
    const { currentBlogUsername, currentNoteKey } = this.props
    this.setState({ currentNote: noteAndFamily, descendants: noteAndFamily.descendants, ancestors: noteAndFamily.ancestors })
    let descendants = noteAndFamily.descendants
    if (isOwnBlog && descendants) {
      const params = queryString.parse(this.props.location.search)
      if (params["add"]) {
        const newSubNoteContent = String(params["add"])
        this.props.history.push(`/${currentBlogUsername}/${currentNoteKey}`)
        if (descendants.length > 0) {
          const lastDescendant = descendants[descendants.length - 1]
          if (lastDescendant.content === "" && getChildren(lastDescendant, descendants).length === 0) {
            descendants[descendants.length - 1].content = newSubNoteContent
            this.setState({ selectedNote: lastDescendant, descendants: descendants })
          } else {
            this.createDescendant(newSubNoteContent)
          }
        } else {
          this.createDescendant(newSubNoteContent)
        }
      } else if (isOwnBlog && descendants.length === 1) {
        this.setState({ selectedNote: descendants[0] })
      } else if (isOwnBlog && descendants.length === 0) {
        this.createDescendant()
      }
    }
    this.setReferences()
  }

  setReferences = () => {
    const { currentNote } = this.state
    const { currentUser } = this.props

    if (currentUser !== undefined ) {
      if (currentNote?.id) {
        const args = {
          include_descendants: true,
          include_ancestors: true,
          include_user: true,
        }
        axios.get<Reference[]>(
          apiDomain() + `/v1/notes/${currentNote.id}/related`,
          {
            params: args,
            headers: { 'Content-Type': 'application/json', "Accept": "application/json" },
            withCredentials: true
          })
          .then(res => {
            this.setState({ references: res.data })
          })
       } else {
         this.setState({ references: [] })
       }
    }
  }

  inCurrentNote = (reference: Reference): boolean => {
    const { currentNote, ancestors } = this.state

    if (ancestors && currentNote) {
      const refRoot = this.getReferenceRoot(reference, reference.ancestors)
      const currentRoot = this.getReferenceRoot(currentNote, ancestors)
      return (sameNote(refRoot, currentRoot))
    } else {
      return (false)
    }
  }

  updateState = (partialState: Partial<UserNotePageState>) => {
    const newState: UserNotePageState = { ...this.state, ...partialState }
    this.setState(newState)
  }

  createDescendant = (content?: string): void => {
    const { currentNote } = this.state
    let { descendants } = this.state
    const { currentUser } = this.props

    if (currentUser && currentNote && descendants) {
      const newNonSavedNote = newNoteWithDescendants({
        position: descendants.length + 1,
        user_id: currentUser.id,
        content: content ||??"",
        ancestry: currentNote.ancestry ? `${currentNote.ancestry}/${currentNote.id}` : String(currentNote.id)
      })
      descendants.push(newNonSavedNote)
      this.setState({ descendants: descendants })
      createBackendNote({ note: newNonSavedNote, setAppState: this.props.setAppState??})
        .then(noteWithId => {
          const { descendants } = this.state
          if (descendants) {
            this.setState({
              descendants: descendants.map((d) => d.tmp_key === noteWithId.tmp_key ? noteWithId : d),
              selectedNote: noteWithId
            })
          }
        })
    }
  }

  getReferenceRoots = (references: Reference[]): Note[] => {
    return (references.map(r => this.getReferenceRoot(r as Note, r.ancestors)))
  }

  getReferenceRoot = (reference: Note, ancestors: Note[]): Note => {
    const root = ancestors.length > 0 ? ancestors[0] : reference
    return (root)
  }

  public render () {
    const { currentBlogger, currentNote, selectedNote, descendants, ancestors, references } = this.state
    const { currentUser, currentNoteKey, currentBlogUsername } = this.props

    if (currentUser && (currentBlogUsername === "notes" || currentBlogUsername === "user" || currentBlogUsername === "note")) {
      this.redirectToUserNote(currentUser.username)
    }
    if (currentBlogger === undefined && currentUser !== undefined) {
      this.fetchBloggerAndCurrentNote()
    }
    const children = currentNote && descendants ? getChildren(currentNote, descendants) : undefined

    const ancestor_count = ancestors ? ancestors.length : 0
    const isOwnBlog = currentUser && currentBlogger && currentUser.id === currentBlogger.id
    const linkToOwnPage = !isOwnBlog && references && currentUser && (currentNote === null || (currentNote && !references.find((t) => t.slug === currentNote.slug && t.user_id === currentUser.id)))
    const currentUsername = currentUser ? currentUser.username : ""
    const ownPagePath = currentNote ? `/${currentUsername}/${currentNote.slug}?content=${currentNote.content}` : `/${currentUsername}/${currentNoteKey}`

    return (
      <>
        <div className="topic-container container">
          {currentBlogger && !currentNote &&
          <h1><a href={`/${currentBlogger.username}`}>{currentBlogger.name}</a></h1>
          }
          {currentBlogger !== null && currentNote === undefined &&
            <p>Loading</p>
          }
          {currentUser && (currentBlogger === null || (currentNote === null && linkToOwnPage)) &&
            <>
              <p>No notes on "{currentNoteKey}" yet.</p>
              <p>
                <Link to={ownPagePath} onClick={() => window.location.href = ownPagePath}>Create your note "{currentNote ? currentNote.content : currentNoteKey}"</Link>.
              </p>
            </>
          }
          {(!currentUser && currentBlogUsername !== "notes" && (currentBlogger === null || currentNote === null)) &&
            <p>No notes on "{currentNoteKey}" yet.</p>
          }
          {currentBlogger && currentNote && children && descendants && ancestors &&
            <>
              {ancestor_count > 0 &&
                <p>
                  {ancestors.map((ancestor, index) => {
                    const path = `/${currentBlogger.username}/${ancestor.slug}`
                    return (
                      <span key={`ancestor_${ancestor.id}`}>
                        <Link
                          to={path}
                          onClick={(event) => {
                            window.location.href = path
                          }}
                        >{ancestor.content ||??"Untitled"}</Link>
                        {(index < ancestor_count - 1) && " > "}
                      </span>
                    )
                  })}
                </p>
              }
              <h1>
                <a href={`/${currentBlogger.username}`}>{currentBlogger.name}</a>
              </h1>
              <CurrentNoteContentRenderer
                descendants={descendants}
                references={references}
                currentNote={currentNote}
                selectedNote={selectedNote}
                setUserNotePageState={this.updateState}
                setAppState={this.props.setAppState}
                currentUser={currentUser} />

              {children.map((subNote) => (
                <div className="top-children" key={subNote.id ||??subNote.tmp_key}>
                  <NoteRenderer
                    currentBlogger={currentBlogger}
                    key={"sub" + noteKey(subNote)}
                    note={subNote}
                    descendants={descendants}
                    siblings={children}
                    currentNote={currentNote}
                    renderSubnotes={true}
                    selectedNote={selectedNote}
                    setUserNotePageState={this.updateState}
                    setAppState={this.props.setAppState}
                    currentUser={currentUser}
                    isReference={false} />
                </div>
              ))}
              {linkToOwnPage &&
                <p className="create-your-note">
                  <Link to={ownPagePath} onClick={() => window.location.href=ownPagePath}>Create your note "{currentNote.content}"</Link>.
                </p>
              }
              {references && references.length > 0 &&
                <div className="all-references">
                  <p>Related:</p>
                  {references.map((ref) => (
                    <ReferenceRenderer
                      key={ref.id}
                      note={ref}
                      selectedNote={selectedNote}
                      setUserNotePageState={this.updateState}
                      setAppState={this.props.setAppState}
                      currentUser={currentUser}
                      showUser={true} />
                  ))}
                </div>
              }
            </>
          }

          {currentUser === null &&
            <LoginOrSignup />
          }
        </div>
      </>
    )
  }
}

export default withRouter(UserNotePage)
