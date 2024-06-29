##########################################################
# Script création identifiants à l'aide d'un fichier CSV #
##########################################################


#/------------------------------\


# Auteur : DEBOVE Esteban
# Date de création : 25/07/2023
# Date de révision : 29/06/2024


#\------------------------------/

#===================================#
# Fonction génération mots de passe #
#===================================#

function Generate-RandomPassword {
    param (
        [int]$Length = 12
    )

    # Liste des caractères utilisés pour générer le mot de passe
    $LowerCaseLetters = "abcdefghijklmnopqrstuvwxyz"
    $UpperCaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $Numbers = "0123456789"
    $SpecialCharacters = "!@#$%^&*()-_=+[{]}\|;:'<>,.?/`~"

    # Créer une liste contenant les types de caractères
    $CharacterTypes = @($LowerCaseLetters, $UpperCaseLetters, $Numbers, $SpecialCharacters)

    # Vérifier si la longueur du mot de passe est inférieure au nombre de types de caractères
    if ($Length -lt $CharacterTypes.Count) 
    {
     
        Write-Error "La longueur du mot de passe doit être supérieure ou égale au nombre de types de caractères."
        return
    
    }

    # Mélanger les types de caractères
    $CharacterTypes = $CharacterTypes | Get-Random -Count $CharacterTypes.Count

    # Générer le mot de passe aléatoire en sélectionnant un caractère de chaque type
    $Password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $CharacterType = $CharacterTypes[$i % $CharacterTypes.Count]
        $RandomIndex = Get-Random -Minimum 0 -Maximum $CharacterType.Length
        $Password += $CharacterType[$RandomIndex]
    }

    return $Password

}

#=======================#
# Le script de création #
#=======================#

# Initialisation des variables
$Path = "OU=xxxxxx,OU=xxxxxx,DC=xxx,DC=xxxxx"
[STRING] $DATE = (Get-Date).ToString("yyyy_MM_dd") 

# Importer les données présentent dans le fichier CSV
$users = Import-Csv -Delimiter "," -Path "C:\le\chemin\du\fichier\csv" # à modifier en fonction du fichier CSV

# Parcourir les données et créer les utilisateurs
foreach ($user in $users) {
    
    # Récupérer les détails de l'utilisateur depuis le CSV
    $SamAccountName = $user.SamAccountName
    $GivenName = $user.GivenName
    $Surname = $user.Surname

    # Génération du mot de passe utilisateur
    $Password = Generate-RandomPassword -Length 14 # à modifier en fonction de la taille du mot de passe souhaité
    
    # Vérifier si l'utilisateur existe déjà dans l'AD
    if (Get-ADUser -Filter {SamAccountName -eq $SamAccountName} -ErrorAction SilentlyContinue) 
    {
    
        echo "! AVERTISSEMENT : Echec de la création. L'utilisateur $GivenName $Surname existe déjà !" >> C:\temp\Create_accounts_$DATE.log
    
    }
    
    else {
        
        # Créer l'utilisateur dans l'AD
        New-ADUser `
            -SamAccountName         "$SamAccountName"  `
            -UserPrincipalName      "$SamAccountName@xxx.xxxxx" `
            -Name                   "$GivenName $Surname" `
            -GivenName              "$GivenName" `
            -SurName                "$Surname" `
            -ChangePasswordAtLogon  $false `
            -DisplayName            "$GivenName $Surname" `
            -Path                   "$Path" `
            -AccountPassword        (convertto-securestring $Password -AsPlainText -Force) `
            -Enabled                $true `
            -PasswordNeverExpires   $true `
            -ErrorAction SilentlyContinue
        
        echo ""
        echo "L'utilisateur $GivenName $Surname a été créé avec succès. Mot de passe : $Password" >> C:\temp\Create_accounts_$DATE.log

    }

}
