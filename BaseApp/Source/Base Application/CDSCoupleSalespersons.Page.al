page 7209 "CDS Couple Salespersons"
{
    Caption = 'Couple Common Data Service Users with Salespersons', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'Create';
    SourceTable = "CRM Systemuser";
    SourceTableView = SORTING(FullName) WHERE(IsIntegrationUser = CONST(false), IsDisabled = CONST(false), IsLicensed = CONST(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(FullName; FullName)
                {
                    ApplicationArea = Suite;
                    Caption = 'User Name Common Data Service', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    Editable = false;
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                }
                field(InternalEMailAddress; InternalEMailAddress)
                {
                    ApplicationArea = Suite;
                    Caption = 'Email Address';
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address.';
                }
                field(SalespersonPurchaserCode; TempCRMSystemuser.FirstName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Salesperson (Business Central)';
                    TableRelation = "Salesperson/Purchaser".Code;
                    ToolTip = 'Specifies the code for the salesperson or purchaser.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                        SalespersonsPurchasers: Page "Salespersons/Purchasers";
                    begin
                        SalespersonsPurchasers.LookupMode(true);
                        if SalespersonsPurchasers.RunModal() = ACTION::LookupOK then begin
                            SalespersonsPurchasers.GetRecord(SalespersonPurchaser);
                            InsertUpdateTempCRMSystemUser(SalespersonPurchaser.Code, true);
                            CleanDuplicateSalespersonRecords(SalespersonPurchaser.Code, SystemUserId);
                        end;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    var
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                    begin
                        if TempCRMSystemuser.FirstName <> '' then begin
                            SalespersonPurchaser.Get(TempCRMSystemuser.FirstName);
                            InsertUpdateTempCRMSystemUser(SalespersonPurchaser.Code, true);
                            CleanDuplicateSalespersonRecords(SalespersonPurchaser.Code, SystemUserId);
                        end else
                            if (TempCRMSystemuser.FirstName = '') and (Coupled = Coupled::Yes) then
                                InsertUpdateTempCRMSystemUser('', true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Create)
            {

                Caption = 'Create Salesperson';

                action(CreateFromCDS)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create Salesperson';
                    Image = NewCustomer;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Create the Common Data Service user as a salesperson in Business Central.';

                    trigger OnAction()
                    var
                        CRMSystemuser: Record "CRM Systemuser";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CurrPage.SetSelectionFilter(CRMSystemuser);
                        CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMSystemuser);
                        HasCreatedFromCds := true;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(SystemUserId, DATABASE::"Salesperson/Purchaser", RecordID) then begin
            if SalespersonPurchaser.Get(RecordID) then
                InsertUpdateTempCRMSystemUser(SalespersonPurchaser.Code, false)
            else
                InsertUpdateTempCRMSystemUser('', false);
            if CurrentlyCoupledCRMSystemuser.SystemUserId = SystemUserId then begin
                Coupled := Coupled::Current;
                FirstColumnStyle := 'Strong';
            end else begin
                Coupled := Coupled::Yes;
                FirstColumnStyle := 'Subordinate';
            end
        end else begin
            InsertUpdateTempCRMSystemUser('', false);
            Coupled := Coupled::No;
            FirstColumnStyle := 'None';
        end;
    end;

    trigger OnInit()
    begin
        Coupled := Coupled::No;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if HasNewlyCoupled() then begin
            ScheduleSalespersonsCoupling();
            exit(true);
        end else
            if Confirm(ClosePageUncoupledUserTxt, true) then
                exit(true);

        exit(false);
    end;

    var
        CurrentlyCoupledCRMSystemuser: Record "CRM Systemuser";
        TempCRMSystemuser: Record "CRM Systemuser" temporary;
        Coupled: Option Yes,No,Current;
        FirstColumnStyle: Text;
        HasCreatedFromCds: Boolean;
        ClosePageUncoupledUserTxt: Label 'No users are coupled to salespersons. Synchronization will succeed only for coupled users and salespersons.\\Do you want to continue?';

    procedure SetCurrentlyCoupledCRMSystemuser(CRMSystemuser: Record "CRM Systemuser")
    begin
        CurrentlyCoupledCRMSystemuser := CRMSystemuser;
    end;

    local procedure InsertUpdateTempCRMSystemUser(SalespersonCode: Code[20]; SyncNeeded: Boolean)
    begin
        // FirstName is used to store coupled/ready to couple Salesperson
        // IsSyncWithDirectory is used to mark CRM User for coupling
        if TempCRMSystemuser.Get(SystemUserId) then begin
            if not TempCRMSystemuser.IsDisabled or SyncNeeded then begin
                TempCRMSystemuser.FirstName := SalespersonCode;
                TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
                TempCRMSystemuser.IsDisabled := SyncNeeded;
                TempCRMSystemuser.Modify();
            end
        end else begin
            TempCRMSystemuser.Init();
            TempCRMSystemuser.SystemUserId := SystemUserId;
            TempCRMSystemuser.FirstName := SalespersonCode;
            TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
            TempCRMSystemuser.IsDisabled := SyncNeeded;
            TempCRMSystemuser.Insert();
        end;
    end;

    local procedure HasNewlyCoupled(): Boolean
    begin
        if HasCreatedFromCds then
            exit(true);

        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        if not TempCRMSystemuser.IsEmpty() then
            exit(true);

        exit(false);

    end;

    local procedure CleanDuplicateSalespersonRecords(SalesPersonCode: Code[20]; CRMUserId: Guid)
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(FirstName, SalesPersonCode);
        TempCRMSystemuser.SetFilter(SystemUserId, '<>' + Format(CRMUserId));
        if TempCRMSystemuser.FindFirst() then begin
            TempCRMSystemuser.IsDisabled := true;
            TempCRMSystemuser.FirstName := '';
            TempCRMSystemuser.Modify();
        end;
    end;

    local procedure ScheduleSalespersonsCoupling()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        OldRecordId: RecordID;
        Synchronize: Boolean;
        Direction: Option;
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        if TempCRMSystemuser.FindSet() then
            repeat
                if TempCRMSystemuser.FirstName <> '' then begin
                    SalespersonPurchaser.Get(TempCRMSystemuser.FirstName);
                    CRMIntegrationManagement.CoupleCRMEntity(
                      SalespersonPurchaser.RecordId, TempCRMSystemuser.SystemUserId, Synchronize, Direction);
                end else begin
                    CRMIntegrationRecord.FindRecordIDFromID(
                      TempCRMSystemuser.SystemUserId, DATABASE::"Salesperson/Purchaser", OldRecordId);
                    CRMCouplingManagement.RemoveCoupling(OldRecordId);
                end;
            until TempCRMSystemuser.Next() = 0;

        TempCRMSystemuser.ModifyAll(IsSyncWithDirectory, false);
        TempCRMSystemuser.ModifyAll(IsDisabled, false);
    end;
}
