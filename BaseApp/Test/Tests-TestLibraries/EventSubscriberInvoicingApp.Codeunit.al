#if not CLEAN21
codeunit 132221 "EventSubscriber Invoicing App"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "O365 Document Sent History" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        InvoiceTok: Label 'INV', Locked = true;
        EmailAddress: Text;
        EmailSubject: Text;
        EmailBody: Text;
        GraphEndpointSuffix: Text;
        HandleJobQueueEntryID: Guid;
        SendEmail: Boolean;
        DoNotSendEmailErr: Label 'Email should not be sent.';
        JobQueueResultOverrideRequested: Boolean;
        NewJobQueueOutcome: Boolean;
        FailureRequestedErr: Label 'Email sending was forced to fail.';
        DoNotRunJobQueue: Boolean;
        AvoidExcessiveRecursion: Boolean;
        AlwaysRunCodeunitNo: Integer;
        ClientTypeToUse: ClientType;
        CustomErrorMessage: Text;

    [Scope('OnPrem')]
    procedure GetEmailBody(): Text
    begin
        exit(EmailBody);
    end;

    [Scope('OnPrem')]
    procedure GetEmailAddress(): Text
    begin
        exit(EmailAddress);
    end;

    [Scope('OnPrem')]
    procedure GetEmailSubject(): Text
    begin
        exit(EmailSubject);
    end;

    [Scope('OnPrem')]
    procedure Clear()
    begin
        SYSTEM.Clear(SendEmail);
        SYSTEM.Clear(EmailBody);
        SYSTEM.Clear(EmailAddress);
        SYSTEM.Clear(EmailSubject);
        SYSTEM.Clear(JobQueueResultOverrideRequested);
        SYSTEM.Clear(GraphEndpointSuffix);
        SYSTEM.Clear(DoNotRunJobQueue);
        SYSTEM.Clear(AlwaysRunCodeunitNo);
        SYSTEM.Clear(NewJobQueueOutcome);
        SYSTEM.Clear(ClientTypeToUse);
        SYSTEM.Clear(CustomErrorMessage);

        if UnbindSubscription(TestClientTypeSubscriber) then;
        if UnbindSubscription(EnvironmentInfoTestLibrary) then;
    end;

    [Scope('OnPrem')]
    procedure SetSendEmail(NewSendEmail: Boolean)
    begin
        SendEmail := NewSendEmail;
    end;

    [Scope('OnPrem')]
    procedure SetRunJobQueueTasks(RunTasks: Boolean)
    begin
        DoNotRunJobQueue := not RunTasks;
    end;

    [Scope('OnPrem')]
    procedure SetGraphEndpointSuffix(Suffix: Text)
    begin
        GraphEndpointSuffix := Suffix;
    end;

    [Scope('OnPrem')]
    procedure SetAppId(NewAppId: Text)
    begin
        EnvironmentInfoTestLibrary.SetAppId(NewAppId);
        BindSubscription(EnvironmentInfoTestLibrary);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure ManuallyRunJobQueueTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true; // Scheduling tasks are not possible while executing tests

        if (HandleJobQueueEntryID = JobQueueEntry.ID) and AvoidExcessiveRecursion then
            exit;

        HandleJobQueueEntryID := JobQueueEntry.ID;

        if DoNotRunJobQueue and (AlwaysRunCodeunitNo <> JobQueueEntry."Object ID to Run") then
            exit;

        // Only execute the job queue if it is scheduled to start today
        // Avoid executing again jobs that already failed or succeeded
        if DT2Date(JobQueueEntry."Earliest Start Date/Time") = Today then
            if not (JobQueueEntry.Status in [JobQueueEntry.Status::Error, JobQueueEntry.Status::Finished]) then begin
                JobQueueEntry.Validate(Status, JobQueueEntry.Status::Ready);
                JobQueueEntry.Modify();
                CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);
            end;
    end;

    [Scope('OnPrem')]
    procedure OverrideJobQueueResult(JobWillBeSuccessful: Boolean)
    begin
        JobQueueResultOverrideRequested := true;
        NewJobQueueOutcome := JobWillBeSuccessful;
    end;

    [Scope('OnPrem')]
    procedure OverrideJobQueueResultWithError(ErrorToShow: Text)
    begin
        OverrideJobQueueResult(false);
        CustomErrorMessage := ErrorToShow;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeDoSending', '', false, false)]
    local procedure SucceedOrFailEmailSending(var CancelSending: Boolean)
    begin
        if JobQueueResultOverrideRequested then begin
            if NewJobQueueOutcome then begin
                CancelSending := true;
                exit;
            end;
            if CustomErrorMessage = '' then
                Error(FailureRequestedErr);

            Error(CustomErrorMessage);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireAcquireOnBehalfOfToken', '', false, false)]
    local procedure OnAcquireAcquireOnBehalfOfToken(ResourceName: Text; var AccessToken: Text)
    begin
        AccessToken := 'TestAccessToken';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCheckProvider', '', false, false)]
    local procedure OnCheckProvider(var Result: Boolean)
    begin
        Result := true;
    end;

    [Scope('OnPrem')]
    procedure SetAlwaysRunCodeunitNo(CodeunitNoToRun: Integer)
    begin
        AlwaysRunCodeunitNo := CodeunitNoToRun;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireOnBehalfOfTokenAndTokenCacheState', '', false, false)]
    local procedure OnAcquireOnBehalfOfTokenAndTokenCacheState(ResourceName: Text; var AccessToken: Text; var TokenCacheState: Text)
    begin
        if ResourceName <> 'TESTRESOURCE' then
            exit;

        AccessToken := 'ACCESSTOKEN';
        TokenCacheState := 'REFRESHTOKEN';
    end;

    [Scope('OnPrem')]
    procedure SetAvoidExcessiveRecursion(NewAvoidExcessiveRecursion: Boolean)
    begin
        AvoidExcessiveRecursion := NewAvoidExcessiveRecursion;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCacheState', '', false, false)]
    local procedure OnAcquireTokenFromCacheState(ResourceName: Text; AadUserId: Text; TokenCacheState: Text; var NewTokenCacheState: Text; var AccessToken: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('REFRESHTOKEN', TokenCacheState, 'Invalid token cache state');

        AccessToken := 'ACCESSTOKEN';
        NewTokenCacheState := 'NEWREFRESHTOKEN';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mail", 'OnGetGraphDomain', '', false, false)]
    local procedure OnGetGraphDomain(var GraphDomain: Text)
    begin
        GraphDomain := 'https://localhost:8080/' + GraphEndpointSuffix;
    end;

    [Scope('OnPrem')]
    procedure SetClientType(NewClientType: ClientType)
    begin
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(NewClientType);
    end;
}
#endif
