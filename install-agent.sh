#!/bin/bash
idUser=`id -u $USER`
export countAgent=`ls -1 $HOME|grep az |wc -l`
export findAgent=`find ~ -iname run.sh | wc -l`
if [ $idUser -ne 0 ]
  then
  echo "Script para incluir novo agente linux no azure devops"
  echo "--------------------------------------------------------------------------"
  echo "Verificar e instalar dependências"
  echo "--------------------------------------------------------------------------"
  list=`apt -qq list jq |grep installed`
  if [ -z "${list}" ]
    then
      echo "Instalar dependências para o node exporter"
      sudo apt update -yq && sudo apt install jq -yq
    else
      echo "Dependências já estão instaladas"
      sleep 2
  fi
  echo "--------------------------------------------------------------------------"
  echo "O usuário para instalação é $USER, e seu diretório de instalação é $HOME"
  echo "--------------------------------------------------------------------------"
  echo "A quantidade de agentes instalado no diretório home é $countAgent"
  
  if [ $findAgent -ne 0 ]
    then
      echo "EXISTE TAMBÉM OUTRAS $findAgent INSTALAÇÕES DE AGENTE QUE SERA LISTADO NO FINAL"
  fi
  sleep 4
  echo "--------------------------------------------------------------------------"
  countAgent=$((countAgent+1))
  echo "O novo agente será instalado em, $HOME com nome az-agent-$countAgent"
  cd ~
  mkdir "az-agent-$countAgent" && cd "az-agent-$countAgent"
  echo "--------------------------------------------------------------------------"
  echo "Verifica últimas versões disponíveis agente azure devops"
  curl -sL https://api.github.com/repos/microsoft/azure-pipelines-agent/tags |jq -r ".[].name" |head -n 5|grep -v x|sed 's/v//g'
  echo "--------------------------------------------------------------------------"
  echo "Escolha a versão do agente do azure devops com base na lista acima"
  echo "--------------------------------------------------------------------------"
  export agentVersion="3.230.2"
  read -p "insira a versão ou pressione enter para utilizar versão default 3.230.2: "  input
    if [ ! -z $input ]
      then
        export agentVersion=$input
    fi
  echo "A versão a ser instalada é $agentVersion"
  sleep 4
  echo "--------------------------------------------------------------------------"
  wget https://vstsagentpackage.azureedge.net/agent/$agentVersion/vsts-agent-linux-x64-$agentVersion.tar.gz && \
  tar zxvf vsts-agent-linux-x64-$agentVersion.tar.gz
  chmod +x config.sh
  clear
  echo "--------------------------------------------------------------------------"
  echo "Informar URL, PAT TOKEN, POOL, AGENT NAME e WORK DIRECTORY"
  read -p "Url da organização azure devops : " urlOrganization
  read -s -p "Token de autenticação PAT: " myToken
  echo ""
  read -p "Definir o pool a ser instalado: " dfPool
  read -p "Definir o nome do agente ou pressione enter para utilizar az-agent-$countAgent : " agentName
  if [ -z $agentName ]
      then
        echo "Será utilizado o nome default com o número da pasta"
        export agentName="az-agent-$countAgent"
  fi
  read -p "Definir o diretório de trabalho ou pressione enter para utilizar o default _work : " directoryWork
  if [ -z $directoryWork ]
      then
        echo "O diretório escolhido é o default"
        export directoryWork="_work"
  fi
  echo "--------------------------------------------------------------------------"
  echo "As opções de instalação a ser utilizadas são: "
  echo "./config.sh --unattended  --url $urlOrganization --auth pat --token $myToken --pool $dfPool --agent $agentName --work $directoryWork"
  read -p "Presione enter para continuar"
  ./config.sh --unattended  --url $urlOrganization --auth pat --token $myToken --pool $dfPool --agent $agentName --work $directoryWork
  export findSvc=`find $HOME/az-agent-$countAgent -maxdepth 2 -iname svc.sh |wc -l`
  echo "--------------------------------------------------------------------------"
  echo "Incluir permissões de acesso ao usuário $HOME"
  sudo chown -R $USER. az-agent-$countAgent
  echo "--------------------------------------------------------------------------"
  if [ $findSvc -ne 0 ]
    then
      echo ""
      echo "Agente Instalado e registrador no pool $dfPool "
      read -p "Presione enter para continuar"
      echo "--------------------------------------------------------------------------"
      echo "Instalar o serviço do agente azure devops no SystemD com o usuário $USER"
      sudo ./svc.sh install $USER
      read -p "Presione enter para continuar"
      echo "--------------------------------------------------------------------------"
      echo "Iniciar o serviço do agente $agentName  pelo SystemD"
      sudo ./svc.sh start
      echo "--------------------------------------------------------------------------"
      echo "Remover arquivo compactado não necessário para o agente"
      rm -f vsts-agent-linux-x64-$agentVersion.tar.gz
      echo "--------------------------------------------------------------------------"
      echo "INSTALAÇÃO REALIZADA COM SUCESSO E O AGENTE ESTÁ ATIVO "
      echo "--------------------------------------------------------------------------"
      echo "ABAIXO ESTÁ A RELAÇÃO DOS AGENTE DO AZURE INSTALADO NESTE USUÁRIO"
      find ~ -maxdepth 2 -type f -iname svc.sh -print
    else
      clear
      echo "INSTALAÇÃO NÃO FOI REALIZADA COM SUCESSO VERIFIQUE AS INFORMAÇÕES DE CREDENCIAIS"
      exit 0
  fi
  read -p "Presione enter para sair"
  else
  echo "O usuário $USER não pode executar este script."
  echo "OBS: O SCRIPT DEVE SER INSTALADO COM UM USUÁRIO COMUM NÃO ROOT"
fi