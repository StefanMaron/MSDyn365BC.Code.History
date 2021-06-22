page 5340 "CRM Systemuser List"
{
    Caption = 'Users - Common Data Service';
    AdditionalSearchTerms = 'Users CDS';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
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
                    Caption = 'Name';
                    Editable = false;
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
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
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    Editable = false;
                    OptionCaption = 'Yes,No,Current';
                    ToolTip = 'Specifies if the Common Data Service record is coupled to Business Central.';
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
                field(TeamMember; TeamMember)
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Team Member';
                    OptionCaption = 'No,Yes';
                    Visible = IsCDSIntegrationEnabled;
                    Editable = false;
                    ToolTip = 'Specifies whether the user is associated with the default team in Common Data Service.';
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
                ToolTip = 'Create the Common Data Service user as a salesperson in Business Central.';
                Visible = ShowCouplingControls;

                trigger OnAction()
                var
                    CRMSystemuser: Record "CRM Systemuser";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMSystemuser);
                    if not CRMIntegrationManagement.HasUncoupledSelectedUsers(CRMSystemuser) then
                        exit;

                    CRMIntegrationManagement.CreateNewSystemUsersFromCRM(CRMSystemuser);
                    HasCoupled := true;

                    if IsCDSIntegrationEnabled then
                        exit;

                    if Confirm(AddScheduledCoupledUsersToTeamQst) then
                        AddUsersToDefaultOwningTeam(CRMSystemuser, false);
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
                ToolTip = 'Link the user in Common Data Service to a salesperson in Business Central.';
                Visible = ShowCouplingControls;

                trigger OnAction()
                var
                    TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
                begin
                    if IsCDSIntegrationEnabled then
                        GetNotInTeamCoupledUsers(TempSelectedCRMSystemuser, true);

                    LinkUsersToSalespersons();

                    if IsCDSIntegrationEnabled then
                        if not TempSelectedCRMSystemuser.IsEmpty() then
                            if Confirm(AddRecentlyCoupledUsersToTeamQst) then
                                AddUsersToDefaultOwningTeam(TempSelectedCRMSystemuser, true);
                end;
            }
            action(AddCoupledUsersToTeam)
            {
                ApplicationArea = Suite;
                Caption = 'Add coupled users to team';
                Image = LinkAccount;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = IsCDSIntegrationEnabled;
                ToolTip = 'Add the coupled Common Data Service users to the default owning team.';

                trigger OnAction()
                var
                    CRMSystemuser: Record "CRM Systemuser";
                begin
                    CurrPage.SetSelectionFilter(CRMSystemuser);
                    AddUsersToDefaultOwningTeam(CRMSystemuser, true);
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
        if IsCDSIntegrationEnabled then begin
            TempCDSTeammembership.SetRange(SystemUserId, SystemUserId);
            if not TempCDSTeammembership.IsEmpty() then
                TeamMember := TeamMember::Yes
            else
                TeamMember := TeamMember::No;
        end;
    end;

    trigger OnInit()
    begin
        Coupled := Coupled::No;
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");

        if CDSConnectionSetup.Get() then begin
            IsCDSIntegrationEnabled := CDSConnectionSetup."Is Enabled";
            if IsCDSIntegrationEnabled then
                CDSIntegrationImpl.GetDefaultOwningTeamMembership(CDSConnectionSetup, TempCDSTeammembership);
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
        CloseWithoutAskingAboutUncoupledUsers: Boolean;
    begin
        if HasCoupled then
            CloseWithoutAskingAboutUncoupledUsers := true
        else
            CloseWithoutAskingAboutUncoupledUsers := not HasUncoupled();

        if CloseWithoutAskingAboutUncoupledUsers then begin
            if not IsCDSIntegrationEnabled then
                exit(true);

            if not HasCoupledNotInTeam() then
                exit(true);

            if Confirm(ClosePageCoupledUserNotInTeamTxt, true) then begin
                GetNotInTeamCoupledUsers(TempSelectedCRMSystemuser, false);
                AddUsersToDefaultOwningTeam(TempSelectedCRMSystemuser, true);
            end;

            exit(true);
        end;

        if Confirm(ClosePageUncoupledUserTxt, true) then
            exit(true);

        exit(false);
    end;

    var
        CurrentlyCoupledCRMSystemuser: Record "CRM Systemuser";
        TempCRMSystemuser: Record "CRM Systemuser" temporary;
        TempCDSTeammembership: Record "CDS Teammembership" temporary;
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        IsCDSIntegrationEnabled: Boolean;
        TeamMember: Option No,Yes;
        Coupled: Option Yes,No,Current;
        FirstColumnStyle: Text;
        AddScheduledCoupledUsersToTeamQst: Label 'New salespersons are scheduled to be coupled.\\Do you want to add the users they are coupled with in Common Data Service to the default owning team so that they can access the synchronized data?';
        AddRecentlyCoupledUsersToTeamQst: Label 'Users in Common Data Service were linked to salespersons.\\ Do you want to add them to the default owning team so that they can access the synchronized data?';
        ClosePageCoupledUserNotInTeamTxt: Label 'Some coupled users are not added to the default owning team in Common Data Service and might not have access to synchronized data.\\Do you want to add them now?';
        ClosePageUncoupledUserTxt: Label 'No Salespersons were scheduled for coupling.\\Are you sure you would like to exit?';
        ShowCouplingControls: Boolean;
        HasCoupled: Boolean;

    procedure SetCurrentlyCoupledCRMSystemuser(CRMSystemuser: Record "CRM Systemuser")
    begin
        CurrentlyCoupledCRMSystemuser := CRMSystemuser;
    end;

    local procedure LinkUsersToSalespersons(): Integer
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
        if TempCRMSystemuser.FindSet() then begin
            HasCoupled := true;
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
        end;
        TempCRMSystemuser.ModifyAll(IsSyncWithDirectory, false);
        TempCRMSystemuser.ModifyAll(IsDisabled, false);
    end;

    local procedure GetNotInTeamCoupledUsers(var TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary; NewlyCoupledOnly: Boolean)
    begin
        TempCRMSystemuser.Reset();
        if NewlyCoupledOnly then
            TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        TempCRMSystemuser.SetFilter(FirstName, '<>%1', '');
        if TempCRMSystemuser.FindSet() then
            repeat
                TempCDSTeammembership.SetRange(SystemUserId, TempCRMSystemuser.SystemUserId);
                if TempCDSTeammembership.IsEmpty() then begin
                    TempSelectedCRMSystemuser.Init();
                    TempSelectedCRMSystemuser.TransferFields(TempCRMSystemuser);
                    TempSelectedCRMSystemuser.Insert();
                end;
            until TempCRMSystemuser.Next() = 0;
    end;

    local procedure AddUsersToDefaultOwningTeam(var CRMSystemuser: Record "CRM Systemuser"; CoupledOnly: Boolean): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
        UserId: Guid;
        Selected: Integer;
        IsCoupled: Boolean;
        Skip: Boolean;
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CRMSystemuser.FindSet() then
            exit;

        CRMIntegrationRecord.SetRange("Table ID", Database::"Salesperson/Purchaser");

        repeat
            UserId := CRMSystemuser.SystemUserId;
            TempCDSTeammembership.SetRange(SystemUserId, UserId);
            if TempCDSTeammembership.IsEmpty() then begin
                if CoupledOnly then begin
                    CRMIntegrationRecord.SetRange("CRM ID", UserId);
                    IsCoupled := not CRMIntegrationRecord.IsEmpty();
                end;
                Skip := (not CoupledOnly) or (CoupledOnly and (not IsCoupled));
                if not Skip then begin
                    TempSelectedCRMSystemuser.Init();
                    TempSelectedCRMSystemuser.TransferFields(CRMSystemuser);
                    TempSelectedCRMSystemuser.Insert();
                    Selected += 1;
                end;
            end;
        until CRMSystemuser.Next() = 0;

        if Selected > 0 then begin
            CDSIntegrationImpl.AddUsersToDefaultOwningTeam(CDSConnectionSetup, TempSelectedCRMSystemuser);
            CDSIntegrationImpl.GetDefaultOwningTeamMembership(CDSConnectionSetup, TempCDSTeammembership);
        end;

        exit(Selected);
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
            TempCRMSystemuser.SystemUserId := SystemUserId;
            TempCRMSystemuser.FirstName := SalespersonCode;
            TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
            TempCRMSystemuser.IsDisabled := SyncNeeded;
            TempCRMSystemuser.Insert();
        end;
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

    local procedure HasUncoupled(): Boolean
    begin
        exit(HasUncoupled(TempCRMSystemuser));
    end;

    local procedure HasUncoupled(var SelectedCRMSystemuser: Record "CRM Systemuser"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        SelectedCRMSystemuser.Reset();
        if SelectedCRMSystemuser.FindSet() then
            repeat
                if not CRMIntegrationRecord.FindRecordIDFromID(SelectedCRMSystemuser.SystemUserId, Database::"Salesperson/Purchaser", RecordID) then
                    exit(true);
            until SelectedCRMSystemuser.Next() = 0;
        exit(false);
    end;

    local procedure HasCoupledNotInTeam(): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        UserId: Guid;
    begin
        TempCRMSystemuser.Reset();
        if TempCRMSystemuser.FindSet() then begin
            CRMIntegrationRecord.SetRange("Table ID", Database::"Salesperson/Purchaser");
            repeat
                UserId := TempCRMSystemuser.SystemUserId;
                TempCDSTeammembership.SetRange(SystemUserId, UserId);
                if TempCDSTeammembership.IsEmpty() then begin
                    CRMIntegrationRecord.SetRange("CRM ID", UserId);
                    if not CRMIntegrationRecord.IsEmpty() then
                        exit(true);
                end;
            until TempCRMSystemuser.Next() = 0;
        end;
        exit(false);
    end;

    procedure Initialize(NewShowCouplingControls: Boolean)
    begin
        ShowCouplingControls := NewShowCouplingControls;
    end;
}

