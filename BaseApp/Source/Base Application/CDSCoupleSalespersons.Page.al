page 7209 "CDS Couple Salespersons"
{
    Caption = 'Couple Dataverse Users with Salespersons', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    InsertAllowed = false;
    PromotedActionCategories = 'Create';
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
                    Caption = 'User Name Dataverse', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    Editable = false;
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
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
                    Editable = true;
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
                    Editable = false;
                    ToolTip = 'Specifies whether the user is associated with the default team in Dataverse.';
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
                    ToolTip = 'Create the Dataverse user as a salesperson in Business Central.';

                    trigger OnAction()
                    var
                        CRMSystemuser: Record "CRM Systemuser";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CurrPage.SetSelectionFilter(CRMSystemuser);
                        if not CRMIntegrationManagement.HasUncoupledSelectedUsers(CRMSystemuser) then
                            exit;

                        CRMIntegrationManagement.CreateNewSystemUsersFromCRM(CRMSystemuser);
                        AddUsersToDefaultOwningTeam(CRMSystemuser, true, false);
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
        TempCDSTeammembership.SetRange(SystemUserId, SystemUserId);
        if not TempCDSTeammembership.IsEmpty() then
            TeamMember := TeamMember::Yes
        else
            TeamMember := TeamMember::No;
    end;

    trigger OnInit()
    begin
        Coupled := Coupled::No;
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        CDSIntegrationImpl.GetDefaultOwningTeamMembership(TempCDSTeammembership);
        Commit();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempNewlyCoupledCRMSystemuser: Record "CRM Systemuser" temporary;
        UsersCount: Integer;
        UsersScheduledForCouplingCount: Integer;
        UsersCoupledCount: Integer;
    begin
        if CloseAction in [CloseAction::LookupOK, CloseAction::Yes, CloseAction::OK] then begin
            UsersScheduledForCouplingCount := GetNewlyCoupledUsers(TempNewlyCoupledCRMSystemuser);
            ScheduleSalespersonsCoupling();
            AddUsersToDefaultOwningTeam(TempNewlyCoupledCRMSystemuser, false, true);
            TempCRMSystemuser.Reset();
            UsersCount := TempCRMSystemuser.Count();
            UsersCoupledCount := CountAlreadyCoupled();

            if UsersCoupledCount + UsersScheduledForCouplingCount = UsersCount then
                exit(true);

            if Confirm(StrSubstNo(ClosePageUncoupledUserTxt, UsersCoupledCount, UsersCount), true) then begin
                ScheduleUncoupledUsersSynch();
                exit(true);
            end;
            Rec.ClearMarks();
        end;
        exit(false);
    end;

    var
        CurrentlyCoupledCRMSystemuser: Record "CRM Systemuser";
        TempCRMSystemuser: Record "CRM Systemuser" temporary;
        TempCDSTeammembership: Record "CDS Teammembership" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CrmHelper: DotNet CrmHelper;
        Initialized: Boolean;
        TeamMember: Option No,Yes;
        Coupled: Option Yes,No,Current;
        FirstColumnStyle: Text;
        HasCreatedFromCds: Boolean;
        ClosePageUncoupledUserTxt: Label '%1 out of %2 users are coupled. To prevent issues in initial synchronization Business Central will create salespeople for uncoupled users, couple them and add them to default team. Would you like to continue?', Comment = '%1=No. of users that were coupled, %2=Total no. of users.';

    procedure SetCurrentlyCoupledCRMSystemuser(CRMSystemuser: Record "CRM Systemuser")
    begin
        CurrentlyCoupledCRMSystemuser := CRMSystemuser;
    end;

    [Scope('OnPrem')]
    procedure Initialize(var NewCrmHelper: DotNet CrmHelper)
    begin
        if IsNull(NewCrmHelper) then begin
            Initialized := false;
            exit;
        end;

        CrmHelper := NewCrmHelper;
        Initialized := true;
    end;

    local procedure GetNewlyCoupledUsers(var TempNewlyCoupledCRMSystemuser: Record "CRM Systemuser" temporary): Integer
    var
        UsersCoupledCount: Integer;
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        TempCRMSystemuser.SetFilter(FirstName, '<>%1', '');
        if TempCRMSystemuser.FindSet() then begin
            UsersCoupledCount := TempCRMSystemuser.Count();
            repeat
                TempCDSTeammembership.SetRange(SystemUserId, TempCRMSystemuser.SystemUserId);
                if TempCDSTeammembership.IsEmpty() then begin
                    TempNewlyCoupledCRMSystemuser.Init();
                    TempNewlyCoupledCRMSystemuser.TransferFields(TempCRMSystemuser);
                    TempNewlyCoupledCRMSystemuser.Insert();

                end;
            until TempCRMSystemuser.Next() = 0;
        end;
        exit(UsersCoupledCount);
    end;

    local procedure AddUsersToDefaultOwningTeam(var CRMSystemuser: Record "CRM Systemuser"; SkipCoupled: Boolean; SkipUncoupled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
        Selected: Integer;
        IsCoupled: Boolean;
        Skip: Boolean;
    begin
        if not Initialized then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CRMSystemuser.FindSet() then
            exit;

        CRMIntegrationRecord.SetRange("Table ID", Database::"Salesperson/Purchaser");

        repeat
            TempCDSTeammembership.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
            if TempCDSTeammembership.IsEmpty() then begin
                CRMIntegrationRecord.SetRange("CRM ID", CRMSystemuser.SystemUserId);
                IsCoupled := not CRMIntegrationRecord.IsEmpty();
                Skip := (SkipCoupled and IsCoupled) or (SkipUncoupled and (not IsCoupled));
                if not Skip then begin
                    TempSelectedCRMSystemuser.Init();
                    TempSelectedCRMSystemuser.TransferFields(CRMSystemuser);
                    TempSelectedCRMSystemuser.Insert();
                    Selected += 1;
                end;
            end;
        until CRMSystemuser.Next() = 0;

        if Selected > 0 then begin
            CDSIntegrationImpl.AddUsersToDefaultOwningTeam(CDSConnectionSetup, CrmHelper, TempSelectedCRMSystemuser);
            CDSIntegrationImpl.GetDefaultOwningTeamMembership(CDSConnectionSetup, TempCDSTeammembership);
        end;
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

    local procedure CountAlreadyCoupled(): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
        CoupledUsersCount: Integer;
    begin
        TempCRMSystemuser.Reset();
        if TempCRMSystemuser.FindSet() then
            repeat
                if CRMIntegrationRecord.FindRecordIDFromID(TempCRMSystemuser.SystemUserId, Database::"Salesperson/Purchaser", RecordID) then
                    CoupledUsersCount := CoupledUsersCount + 1
                else begin
                    Rec.get(TempCRMSystemuser.SystemUserId);
                    Rec.Mark(true);
                end;
            until TempCRMSystemuser.Next() = 0;
        exit(CoupledUsersCount);
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

    local procedure ScheduleUncoupledUsersSynch()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Rec.MarkedOnly();
        CRMIntegrationManagement.CreateNewSystemUsersFromCRM(Rec);
        AddUsersToDefaultOwningTeam(Rec, true, false);
    end;
}
