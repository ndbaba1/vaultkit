# frozen_string_literal: true

class Api::V1::ApprovalsController < Api::BaseController
  before_action :require_org!

  def index
    state = params[:state] || "pending"

    audit(
      "approval.list.requested",
      details: { state: state }
    )

    approvals =
      PolicyApproval
        .where(organization: current_org, state: state)
        .order(created_at: :desc)

    approvals =
      approvals.select { |a| can_act_on?(a) }

    audit(
      "approval.list.returned",
      details: { state: state, count: approvals.size }
    )

    render json: approvals.map { |a| serialize(a) }
  end

  def approve
    approval = find_approval!

    raise PolicyApprovals::SelfApprovalError,
      "Cannot approve your own request" if approval.requester == current_user

    audit(
      "approval.approve.initiated",
      details: {
        approval_id: approval.id,
        dataset: approval.dataset,
        fields: approval.fields
      }
    )

    PolicyApprovals::Service.new.approve!(
      approval: approval,
      approver: current_user,
      ttl_seconds: params.fetch(:ttl_seconds, 3600)
    )

    audit(
      "approval.approved",
      details: {
        approval_id: approval.id,
        dataset: approval.dataset,
        fields: approval.fields,
        grant_ref: approval.grant&.ref,
        expires_at: approval.grant&.expires_at
      }
    )

    render json: {
      status: "approved",
      grant_ref: approval.grant&.ref,
      expires_at: approval.grant&.expires_at
    }
  rescue PolicyApprovals::SelfApprovalError => e
    audit(
      "approval.approve.failed",
      details: {
        approval_id: params[:id],
        error: e.message
      }
    )
  
    render json: { error: e.message }, status: :forbidden
  
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Approval not found" }, status: :not_found
  end

  def deny
    approval = find_approval!

    raise PolicyApprovals::SelfApprovalError, 
      "Cannot deny your own request" if approval.requester == current_user

    reason = params[:reason].presence || raise("Denial reason required")

    audit(
      "approval.deny.initiated",
      details: {
        approval_id: approval.id,
        dataset: approval.dataset,
        fields: approval.fields
      }
    )

    PolicyApprovals::Service.new.deny!(
      approval: approval,
      approver: current_user,
      reason: reason
    )

    audit(
      "approval.denied",
      details: {
        approval_id: approval.id,
        dataset: approval.dataset,
        fields: approval.fields,
        reason: reason
      }
    )

    render json: { status: "denied" }
  rescue PolicyApprovals::SelfApprovalError => e
    audit(
      "approval.deny.failed",
      details: {
        approval_id: params[:id],
        error: e.message
      }
    )
  
    render json: { error: e.message }, status: :forbidden

  rescue => e
    audit(
      "approval.deny.failed",
      details: {
        approval_id: params[:id],
        error: e.message
      }
    )
    raise
  end

  private

  def find_approval!
    PolicyApproval.find_by!(
      id: params[:id],
      organization: current_org
    )
  end

  def can_act_on?(approval)
    return true if current_user.admin?

    required  = approval.approver_role
    user_role = current_user.role

    return false if approval.requester == current_user
    return true if user_role == "approver"

    required.nil? || required == user_role
  end

  def serialize(approval)
    {
      id: approval.id,
      dataset: approval.dataset,
      fields: approval.fields,
      requester: approval.requester.email,
      approver_role: approval.approver_role,
      reason: approval.reason,
      state: approval.state,
      created_at: approval.created_at,
      approved_at: approval.approved_at,
      grant_ref: approval&.grant&.ref
    }
  end

  def audit(event, details:)
    AUDIT_LOGGER.log(
      event: event,
      actor: current_user,
      organization: current_org,
      details: details
    )
  end
end
