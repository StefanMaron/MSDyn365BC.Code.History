page 5333 "CRM Skipped Records"
{
    AccessByPermission = TableData "CRM Integration Record" = R;
    ApplicationArea = Suite;
    Caption = 'Coupled Data Synchronization Errors';
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Synchronization,Broken Couplings';
    SourceTable = "CRM Synch. Conflict Buffer";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the table that holds the record.';
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the table that holds the record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the description of the table that holds the record.';

                    trigger OnDrillDown()
                    begin
                        CRMSynchHelper.ShowPage("Record ID");
                    end;
                }
                field("Record Exists"; "Record Exists")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the coupled record exists in Business Central.';
                }
                field("Int. Description"; "Int. Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled To';
                    ToolTip = 'Specifies the coupled entity in Dynamics 365 Sales ';

                    trigger OnDrillDown()
                    begin
                        CRMSynchHelper.ShowPage("Int. Record ID");
                    end;
                }
                field("Int. Record Exists"; "Int. Record Exists")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled Record Exists';
                    ToolTip = 'Specifies if a coupled entity exists in Dynamics 365 Sales';
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies why the record was could not be synchronized.';
                }
                field("Failed On"; "Failed On")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the synchronization failed.';
                }
                field("Deleted On"; "Deleted On")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the record was deleted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Restore)
            {
                AccessByPermission = TableData "CRM Integration Record" = IM;
                ApplicationArea = Suite;
                Caption = 'Retry';
                Enabled = AreRecordsExist AND DoBothOfRecordsExist;
                Image = ResetStatus;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Restore selected records for further Dynamics 365 Sales synchronization.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    SetCurrentSelectionFilter(CRMIntegrationRecord);
                    CRMIntegrationManagement.UpdateSkippedNow(CRMIntegrationRecord);
                    Refresh(CRMIntegrationRecord);
                end;
            }
            action(CRMSynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize';
                Enabled = AreRecordsExist AND DoBothOfRecordsExist;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Send or get updated data to or from Dynamics 365 Sales.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    SetCurrentSelectionFilter(CRMIntegrationRecord);
                    CRMIntegrationRecord.Skipped := false;
                    CRMIntegrationRecord.Modify;
                    Refresh(CRMIntegrationRecord);
                    CRMIntegrationManagement.UpdateMultipleNow(CRMIntegrationRecord);
                    Refresh(CRMIntegrationRecord);
                end;
            }
            action(ShowLog)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronization Log';
                Enabled = AreRecordsExist AND "Record Exists";
                Image = Log;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                ToolTip = 'View integration synchronization jobs for the skipped record.';

                trigger OnAction()
                var
                    IntegrationRecord: Record "Integration Record";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    IntegrationRecord.FindByIntegrationId("Integration ID");
                    CRMIntegrationManagement.ShowLog(IntegrationRecord."Record ID");
                end;
            }
            action(ManageCRMCoupling)
            {
                ApplicationArea = Suite;
                Caption = 'Set Up Coupling';
                Enabled = AreRecordsExist AND "Record Exists";
                Image = LinkAccount;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales entity.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    IntegrationRecord: Record "Integration Record";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    IntegrationRecord.Get("Integration ID");
                    if CRMIntegrationRecord.FindByRecordID(IntegrationRecord."Record ID") then
                        if CRMIntegrationManagement.DefineCoupling(IntegrationRecord."Record ID") then begin
                            CRMIntegrationRecord.SetRecFilter;
                            Refresh(CRMIntegrationRecord);
                        end;
                end;
            }
            action(DeleteCRMCoupling)
            {
                AccessByPermission = TableData "CRM Integration Record" = D;
                ApplicationArea = Suite;
                Caption = 'Remove Coupling';
                Enabled = AreRecordsExist;
                Image = UnLinkAccount;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                ToolTip = 'Delete the coupling to a Dynamics 365 Sales entity.';

                trigger OnAction()
                begin
                    DeleteCoupling;
                    AreRecordsExist := false;
                end;
            }
            action(RestoreDeletedRec)
            {
                ApplicationArea = Suite;
                Caption = 'Restore Records';
                Enabled = AreRecordsExist AND IsOneOfRecordsDeleted;
                Image = CreateMovement;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Restore the deleted coupled entity in Dynamics 365 Sales. A synchronization job is run to achieve this.';

                trigger OnAction()
                var
                    TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
                begin
                    TempCRMSynchConflictBuffer.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
                    TempCRMSynchConflictBuffer.RestoreDeletedRecords;
                end;
            }
            action(DeleteCoupledRec)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Records';
                Enabled = AreRecordsExist AND IsOneOfRecordsDeleted;
                Image = CancelLine;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Delete the coupled entity in Dynamics 365 Sales.';

                trigger OnAction()
                var
                    TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
                begin
                    TempCRMSynchConflictBuffer.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
                    TempCRMSynchConflictBuffer.DeleteCoupledRecords;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        AreRecordsExist := true;
        IsOneOfRecordsDeleted := IsOneRecordDeleted;
        DoBothOfRecordsExist := DoBothRecordsExist;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
        if not SetOutside and CRMIntegrationEnabled then
            CollectSkippedCRMIntegrationRecords;
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMIntegrationEnabled: Boolean;
        AreRecordsExist: Boolean;
        IsOneOfRecordsDeleted: Boolean;
        DoBothOfRecordsExist: Boolean;
        SetOutside: Boolean;

    local procedure CollectSkippedCRMIntegrationRecords()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.SetRange(Skipped, true);
        SetRecords(CRMIntegrationRecord);
    end;

    local procedure SetCurrentSelectionFilter(var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
        TempCRMSynchConflictBuffer.SetSelectionFilter(CRMIntegrationRecord);
    end;

    procedure SetRecords(var CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        Fill(CRMIntegrationRecord);
        SetOutside := true;
    end;

    local procedure Refresh(var CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        UpdateSourceTable(CRMIntegrationRecord);
        AreRecordsExist := false;
    end;
}

