function process(r::Request{Val{Symbol("textDocument/signatureHelp")},TextDocumentPositionParams}, server)
    tdpp = r.params
    line = get_line(tdpp,server)
    pos = pos0 = min(tdpp.position.character+1,length(line))
    
    arg,b = 0,0
    word = ""
    pos-=line[pos]==')' 
    while pos>1
        info(pos)
        if line[pos]=='(' 
            if b == 0
                 word = get_word(tdpp,server,pos-pos0)
                break
            elseif b>0
                b-=1
            end
        elseif line[pos]==',' && b==0
            arg+=1
        elseif line[pos] == ')'
            b+=1
        end
        pos-=1
    end
    
    if word==""
        response = Response(get(r.id),CancelParams(Dict("id"=>get(r.id))))
    else
        x = get_sym(word)
        M = methods(x).ms
        sigs = map(M) do m
            tv, decls, file, line = Base.arg_decl_parts(m)
            p_sigs = [isempty(i[2]) ? i[1] : i[1]*"::"*i[2] for i in decls[2:end]]
            desc = string(string(m.name), "(",join(p_sigs, ", "),")")

            PI = map(ParameterInformation,p_sigs)
            # Extract documentation here
            doc = ""
            return SignatureInformation(desc,doc,PI)
        end
        signatureHelper = SignatureHelp(sigs,0,arg)
        response = Response(get(r.id),signatureHelper)
    end
    send(response,server)
end


function JSONRPC.parse_params(::Type{Val{Symbol("textDocument/signatureHelp")}}, params)
    return TextDocumentPositionParams(params)
end