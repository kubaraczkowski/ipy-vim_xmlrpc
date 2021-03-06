" commented for now, no customized environments yet, he
if !exists("$IPY_SESSION")
    finish
endif

" set up the python interpreter within vim, to have all the right modules
" imported, as well as certain useful globals set
python import xmlrpclib
python import os
python import vim
"python from IPython.Debugger import Pdb
python IPYSERVER = None
python reselect = True

python << EOF
# do we have a connection to the ipython instance?
def check_server():
    global IPYSERVER
    if IPYSERVER is not None:
        return True
    else:
        return False

# connect to the ipython server, if we need to
def connect():
    global IPYSERVER
    if check_server():
        return
    try:
        #IPYSERVER = xmlrpclib.ServerProxy('http://localhost:9876')
        IPYSERVER = xmlrpclib.ServerProxy(os.environ.get('IPY_SERVER'))
        # this is fixed for now
        #        IPYSERVER.connect(os.environ.get('IPY_SERVER'))
    except:
        IPYSERVER = None

def disconnect():
    if IPYSERVER:
        IPYSERVER.close()

def send(cmd):
    IPYSERVER.send(cmd)

def run_this_file():
    if check_server():
        send('run  %s' % (get_proper_filename(),))
    else:
        raise Exception, "Not connected to an IPython server"
    print "\'run %s\' sent to ipython" % get_proper_filename()

def run_this_line():
    if check_server():
        send(vim.current.line)
        print "line \'%s\' sent to ipython"% vim.current.line
    else:
        raise Exception, "Not connected to an IPython server"

def get_proper_filename():
    # turn on shellslashing
    vim.command('set ssl')
    filename = vim.current.buffer.name # proper one with slashes
    return filename

def run_these_lines(mode='norm'):
    if check_server():
        r = vim.current.range
        if r.start == r.end:
            run_this_line()
        else:
            for l in vim.current.buffer[r.start:r.end+1]:
                send(str(l)+'\n')
            if mode == 'norm':
                print "line %d sent to ipython"% (r.start+1)
            elif mode == 'vis':
                #reselect the previously highlighted block
                if reselect:
                    vim.command("normal gv")
                #vim lines start with 1
                print "lines %d-%d sent to ipython"% (r.start+1,r.end+1)
            else:
                raise Exception, "mode not recognized"
    else:
        raise Exception, "Not connected to an IPython server"

def toggle_reselect():
    global reselect
    reselect=not reselect
    print "F9 will%sreselect lines after sending to ipython"% (reselect and " " or " not ")

def set_breakpoint():
    if check_server():
        send("__IP.InteractiveTB.pdb.set_break('%s',%d)" % (get_proper_filename(),
                                                            vim.current.window.cursor[0]))
        print "set breakpoint in %s:%d"% (get_proper_filename(), 
                                          vim.current.window.cursor[0])
    else:
        raise Exception, "Not connected to an IPython server"
    
def clear_breakpoint():
    if check_server():
        send("__IP.InteractiveTB.pdb.clear_break('%s',%d)" % (get_proper_filename(),
                                                              vim.current.window.cursor[0]))
        print "clearing breakpoint in %s:%d" % (get_proper_filename(),
                                                vim.current.window.cursor[0])
    else:
        raise Exception, "Not connected to an IPython server"

def clear_all_breakpoints():
    if check_server():
        send("__IP.InteractiveTB.pdb.clear_all_breaks()");
        print "clearing all breakpoints"
    else:
        raise Exception, "Not connected to an IPython server"

def run_this_file_pdb():
    if check_server():
        send(' __IP.InteractiveTB.pdb.run(\'execfile("%s")\')' % (get_proper_filename(),))
    else:
        raise Exception, "Not connected to an IPython server"
    print "\'run %s\' using pdb sent to ipython" % get_proper_filename()

    #XXX: have IPYSERVER print the prompt (look at Leo example)
EOF

fun! <SID>toggle_send_on_save()
    if exists("s:ssos") && s:ssos == 1
        let s:ssos = 0
        au! BufWritePost *.py
        echo "Autosend Off"
    else
        let s:ssos = 1
        au BufWritePost *.py :py run_this_file()
        echo "Autosend On"
    endif
endfun

map <silent> <F5> :python run_this_file()<CR>
"map <silent> <F5> :python run_this_line()<CR>
map <silent> <F4> :python run_these_lines(mode='norm')<CR>
vmap <silent> <F4> :python run_these_lines(mode='vis')<CR>
map <silent> <C-F6> :python send('%pdb')<CR>
map <silent> <F6> :python set_breakpoint()<CR>
map <silent> <s-F6> :python clear_breakpoint()<CR>
map <silent> <F7> :python run_this_file_pdb()<CR>
map <silent> <s-F7> :python clear_all_breakpoints()<CR>
map <F9> :call <SID>toggle_send_on_save()<CR>
map <silent> <S-F9> :python toggle_reselect()<CR>
imap <F4> <ESC><F4>a
imap <C-F5> <ESC><C-F5>a
imap <silent> <F5> <ESC><F5>a
map <C-F5> :call <SID>toggle_send_on_save()<CR>
py connect()
