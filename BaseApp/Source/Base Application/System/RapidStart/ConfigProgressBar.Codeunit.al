namespace System.IO;

codeunit 8615 "Config. Progress Bar"
{

    trigger OnRun()
    begin
    end;

    var
        Window: Dialog;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '#1##################\\';
        Text001: Label '#2##################\';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MaxCount: Integer;
#pragma warning disable AA0074
        Text002: Label '@3@@@@@@@@@@@@@@@@@@\';
#pragma warning restore AA0074
        StepCount: Integer;
        Counter: Integer;
        LastWindowText: Text;
        WindowTextCount: Integer;

    procedure Init(NewMaxCount: Integer; NewStepCount: Integer; WindowTitle: Text)
    var
        ProgressBarText: Text;
    begin
        Counter := 0;
        MaxCount := NewMaxCount;
        if NewStepCount = 0 then
            NewStepCount := 1;
        StepCount := NewStepCount;

        ProgressBarText := Text000 + Text001 + Text002;
        OnInitOnBeforeWindowOpen(Window, ProgressBarText);
        Window.Open(ProgressBarText);
        Window.Update(1, Format(WindowTitle));
        Window.Update(3, 0);

        OnAfterInit(Window);
    end;

    procedure Update(WindowText: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdate(WindowText, Window, IsHandled);
        if not IsHandled then
            if WindowText <> '' then begin
                Counter := Counter + 1;
                if Counter mod StepCount = 0 then begin
                    Window.Update(2, Format(WindowText));
                    if MaxCount <> 0 then
                        Window.Update(3, Round(Counter / MaxCount * 10000, 1));
                end;
            end;
        OnAfterUpdate(WindowText, Window);
    end;

    [TryFunction]
    procedure UpdateCount(WindowText: Text; "Count": Integer)
    begin
        if WindowText <> '' then begin
            if LastWindowText = WindowText then
                WindowTextCount += 1
            else
                WindowTextCount := 0;
            LastWindowText := WindowText;
            Window.Update(2, PadStr(WindowText + ' ', StrLen(WindowText) + WindowTextCount, '.'));
            if MaxCount <> 0 then
                Window.Update(3, Round((MaxCount - Count) / MaxCount * 10000, 1));
        end;
    end;

    procedure Close()
    begin
        Window.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInit(var Window: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdate(WindowText: Text; var Window: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdate(WindowText: Text; var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitOnBeforeWindowOpen(var Window: Dialog; var ProgressBarText: Text)
    begin
    end;
}

