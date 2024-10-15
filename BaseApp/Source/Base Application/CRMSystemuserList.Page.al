page 5340 "CRM Systemuser List"
{
    Caption = 'Users - Microsoft Dynamics 365 Sales';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "CRM Systemuser";
    SourceTableView = SORTING(FullName);

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
                    Caption = 'Name';
                    Editable = false;
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(InternalEMailAddress; InternalEMailAddress)
                {
                    ApplicationArea = Suite;
                    Caption = 'Email Address';
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address.';
                }
                field(MobilePhone; MobilePhone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Mobile Phone';
                    Editable = false;
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    Editable = false;
                    OptionCaption = 'Yes,No,Current';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Dynamics 365.';
                }
                field(SalespersonPurchaserCode; TempCRMSystemuser.FirstName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Salesperson/Purchaser Code';
                    Enabled = ShowCouplingControls;
                    TableRelation = "Salesperson/Purchaser".Code;
                    ToolTip = 'Specifies the code for the salesperson or purchaser.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                        SalespersonsPurchasers: Page "Salespersons/Purchasers";
                    begin
                        SalespersonsPurchasers.LookupMode(true);
                        if SalespersonsPurchasers.RunModal = ACTION::LookupOK then begin
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
        area(creation)
        {
            action(CreateFromCRM)
            {
                ApplicationArea = Suite;
                Caption = 'Create Salesperson in Business Central';
                Image = NewCustomer;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create the Dynamics 365 Sales user as a salesperson in Business Central.';
                Visible = ShowCouplingControls;

                trigger OnAction()
                var
                    CRMSystemuser: Record "CRM Systemuser";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMSystemuser);
                    CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMSystemuser);
                end;
            }
            action(Couple)
            {
                ApplicationArea = Suite;
                Caption = 'Couple';
                Image = LinkAccount;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Link the user in Dynamics 365 Sales to a user in Business Central.';
                Visible = ShowCouplingControls;

                trigger OnAction()
                var
                    SalespersonPurchaser: Record "Salesperson/Purchaser";
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    CRMCouplingManagement: Codeunit "CRM Coupling Management";
                    OldRecordId: RecordID;
                    Synchronize: Boolean;
                    Direction: Option;
                begin
                    TempCRMSystemuser.Reset;
                    TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
                    if TempCRMSystemuser.FindSet then
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
                        until TempCRMSystemuser.Next = 0;
                    TempCRMSystemuser.ModifyAll(IsSyncWithDirectory, false);
                    TempCRMSystemuser.ModifyAll(IsDisabled, false);
                end;
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
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    begin
        SetRange(IsIntegrationUser, false);
        SetRange(IsDisabled, false);
        SetRange(IsLicensed, true);
    end;

    var
        CurrentlyCoupledCRMSystemuser: Record "CRM Systemuser";
        TempCRMSystemuser: Record "CRM Systemuser" temporary;
        Coupled: Option Yes,No,Current;
        FirstColumnStyle: Text;
        ShowCouplingControls: Boolean;

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
                TempCRMSystemuser.Modify;
            end
        end else begin
            TempCRMSystemuser.SystemUserId := SystemUserId;
            TempCRMSystemuser.FirstName := SalespersonCode;
            TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
            TempCRMSystemuser.IsDisabled := SyncNeeded;
            TempCRMSystemuser.Insert;
        end;
    end;

    local procedure CleanDuplicateSalespersonRecords(SalesPersonCode: Code[20]; CRMUserId: Guid)
    begin
        TempCRMSystemuser.Reset;
        TempCRMSystemuser.SetRange(FirstName, SalesPersonCode);
        TempCRMSystemuser.SetFilter(SystemUserId, '<>' + Format(CRMUserId));
        if TempCRMSystemuser.FindFirst then begin
            TempCRMSystemuser.IsDisabled := true;
            TempCRMSystemuser.FirstName := '';
            TempCRMSystemuser.Modify;
        end;
    end;

    procedure Initialize(NewShowCouplingControls: Boolean)
    begin
        ShowCouplingControls := NewShowCouplingControls;
    end;
}

