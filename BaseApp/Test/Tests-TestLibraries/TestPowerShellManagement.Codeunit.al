codeunit 130550 TestPowerShellManagement
{

    trigger OnRun()
    begin
    end;

    var
        [RunOnClient]
        PowerShell: DotNet "System.Management.Automation.PowerShell";
        [RunOnClient]
        Runspace: DotNet "System.Management.Automation.RunSpaces.Runspace";
        [RunOnClient]
        Pipeline: DotNet "System.Management.Automation.Runspaces.Pipeline";
        [RunOnClient]
        InitialSessionState: DotNet "System.Management.Automation.Runspaces.InitialSessionState";
        [RunOnClient]
        PowerShellCommands: DotNet "System.Management.Automation.PSCommand";
        [RunOnClient]
        Collection: DotNet Collection1;
        SessionIsInitialized: Boolean;
        PowerShellCommandsInitialized: Boolean;

    [Scope('OnPrem')]
    procedure GetNextLine(pos: Integer) line: Text
    begin
        if pos >= Collection.Count then
            exit('');
        line := Collection.Item(pos);
    end;

    [Scope('OnPrem')]
    procedure InitPowerShell()
    begin
        PowerShell := PowerShell.Create(InitialSessionState);
        Runspace := PowerShell.Runspace;
        Pipeline := Runspace.CreatePipeline;
    end;

    [Scope('OnPrem')]
    procedure AddPowerShellScript(Script: Text)
    begin
        if PowerShellCommandsInitialized then
            exit;
        InitPowerShellCommands;
        PowerShellCommands.AddScript(Script);
    end;

    [Scope('OnPrem')]
    procedure InvokePowerShell()
    var
        [RunOnClient]
        PipelineCommands: DotNet "System.Management.Automation.Runspaces.CommandCollection";
    begin
        PipelineCommands := Pipeline.Commands;
        AddPowerShellCommandsToPipeline(PowerShellCommands.Commands, PipelineCommands);
        Collection := Pipeline.Invoke;
    end;

    [Scope('OnPrem')]
    procedure GetPowerShellResult(var ResultCollection: DotNet Collection1)
    begin
        ResultCollection := Collection;
    end;

    [Scope('OnPrem')]
    procedure GetPowerShellResultCount(): Integer
    begin
        exit(Collection.Count);
    end;

    [Scope('OnPrem')]
    procedure CreateInitialSessionState()
    begin
        if SessionIsInitialized then
            exit;
        InitialSessionState := InitialSessionState.CreateDefault;
        SessionIsInitialized := true;
    end;

    local procedure InitPowerShellCommands()
    begin
        if PowerShellCommandsInitialized then
            exit;
        PowerShellCommands := PowerShellCommands.PSCommand;
        PowerShellCommandsInitialized := true;
    end;

    local procedure AddPowerShellCommandsToPipeline(FromCommandsCollection: DotNet "System.Management.Automation.Runspaces.CommandCollection"; ToCommandsCollection: DotNet "System.Management.Automation.Runspaces.CommandCollection")
    var
        [RunOnClient]
        Enumerator: DotNet GenericIEnumerator1;
        [RunOnClient]
        Command: DotNet "System.Management.Automation.Runspaces.Command";
        i: Integer;
    begin
        Enumerator := FromCommandsCollection.GetEnumerator;
        for i := 1 to FromCommandsCollection.Count do begin
            Enumerator.MoveNext;
            Command := Enumerator.Current;
            ToCommandsCollection.Add(Command)
        end
    end;
}

