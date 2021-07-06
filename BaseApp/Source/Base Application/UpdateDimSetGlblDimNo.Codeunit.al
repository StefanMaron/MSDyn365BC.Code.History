codeunit 482 "Update Dim. Set Glbl. Dim. No."
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "General Ledger Setup" = rm,
                  tabledata "Dimension Set Entry" = rm;

    trigger OnRun()
    begin
        UpdateDimSetEntryGlobalDimNo();
    end;

    var
        Counter: Integer;
        Window: Dialog;
        ProgressBarMsg: Label 'Processing: @1@@@@@@@';

    procedure UpdateDimSetEntryGlobalDimNo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        UpdateDimSetGlblDimNo: Codeunit "Update Dim. Set Glbl. Dim. No.";
        DimFilterString: Text;
    begin
        BindSubscription(UpdateDimSetGlblDimNo);
        OpenProgressDialog();
        GeneralLedgerSetup.Get();

        if GeneralLedgerSetup."Shortcut Dimension 3 Code" <> '' then begin
            DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 3 Code");
            DimensionSetEntry.ModifyAll("Global Dimension No.", 3, false);
            DimFilterString += '&<>' + GeneralLedgerSetup."Shortcut Dimension 3 Code";
        end;
        UpdateProgressDialog();

        if GeneralLedgerSetup."Shortcut Dimension 4 Code" <> '' then begin
            DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 4 Code");
            DimensionSetEntry.ModifyAll("Global Dimension No.", 4, false);
            DimFilterString += '&<>' + GeneralLedgerSetup."Shortcut Dimension 4 Code";
        end;
        UpdateProgressDialog();

        if GeneralLedgerSetup."Shortcut Dimension 5 Code" <> '' then begin
            DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 5 Code");
            DimensionSetEntry.ModifyAll("Global Dimension No.", 5, false);
            DimFilterString += '&<>' + GeneralLedgerSetup."Shortcut Dimension 5 Code";
        end;
        UpdateProgressDialog();

        if GeneralLedgerSetup."Shortcut Dimension 6 Code" <> '' then begin
            DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 6 Code");
            DimensionSetEntry.ModifyAll("Global Dimension No.", 6, false);
            DimFilterString += '&<>' + GeneralLedgerSetup."Shortcut Dimension 6 Code";
        end;
        UpdateProgressDialog();

        if GeneralLedgerSetup."Shortcut Dimension 7 Code" <> '' then begin
            DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 7 Code");
            DimensionSetEntry.ModifyAll("Global Dimension No.", 7, false);
            DimFilterString += '&<>' + GeneralLedgerSetup."Shortcut Dimension 7 Code";
        end;
        UpdateProgressDialog();

        if GeneralLedgerSetup."Shortcut Dimension 8 Code" <> '' then begin
            DimensionSetEntry.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 8 Code");
            DimensionSetEntry.ModifyAll("Global Dimension No.", 8, false);
            DimFilterString += '&<>' + GeneralLedgerSetup."Shortcut Dimension 8 Code";
        end;
        UpdateProgressDialog();

        IF DimFilterString <> '' then begin
            DimFilterString := DelChr(DimFilterString, '<', '&');
            DimensionSetEntry.SetFilter("Dimension Code", DimFilterString);
        end;
        DimensionSetEntry.ModifyAll("Global Dimension No.", 0, false);
        UpdateProgressDialog();

        CloseProgressDialog();
        UnbindSubscription(UpdateDimSetGlblDimNo);
    end;

    local procedure OpenProgressDialog()
    begin
        Counter := 0;
        if GuiAllowed then
            Window.Open(ProgressBarMsg);
    end;

    local procedure UpdateProgressDialog()
    begin
        Counter += 1;
        if GuiAllowed then
            Window.Update(1, Round(counter / 7 * 10000, 1));
    end;

    local procedure CloseProgressDialog()
    begin
        if GuiAllowed then
            Window.Close();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnAfterIsAlwaysLoggedTable', '', false, false)]
    local procedure OnAfterIsAlwaysLoggedTableHandler(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
        if TableID = Database::"Dimension Set Entry" then
            AlwaysLogTable := true;
    end;
}