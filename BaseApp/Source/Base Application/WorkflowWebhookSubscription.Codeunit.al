codeunit 1544 "Workflow Webhook Subscription"
{

    trigger OnRun()
    begin
    end;

    procedure Approve(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.ContinueByStepInstanceId(WorkflowStepInstanceId);
    end;

    procedure Reject(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.RejectByStepInstanceId(WorkflowStepInstanceId);
    end;
}

