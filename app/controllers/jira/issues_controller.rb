# frozen_string_literal: true

# Jira issues integration controller
class Jira::IssuesController < ApplicationController
  before_action :authorize

  def index
    puts params
  end

  def show
    puts params
  end

  def create
    puts params
  end

  def update
    puts params
  end

  def destroy
    puts params
  end

  private

  def authorize
  end
end
