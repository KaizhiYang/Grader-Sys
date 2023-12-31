Rails.application.routes.draw do
  resources :requests, only: [:create, :new]
  resources :sections
  resources :evaluations, only: [:create, :new]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks'
  }

  authenticated :user do
    root 'courses#index', as: :authenticated_root
  end

  devise_scope :user do
    unauthenticated :user do
      root to: 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  # authenticated :user do
  #   root 'placeholder#welcome', as: :authenticated_root
  # end

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  get 'student_information', to: 'students#information', as: 'student_information'
  # lab3 part
  resources :students do
    collection do
      post 'setInfo'
      delete 'delete_all_times'
    end
  end
  
  # # Defines the root path route ("/")
  # root "courses#index"
  resources :courses, only: [:index]
  
   # Reset database route
  post '/reset_courses', to: 'courses#reset'

  # Edit course route
  get 'courses/edit', to: 'courses#edit'

  # New course route
  get 'courses/new', to: 'courses#new'

  #Redirect show page to course index
  get 'courses/:id', to: 'courses#index'

  # This line will cause add section button not working
  # get 'courses/:id/sections/:id', to: 'courses#index'


  # courses/course_id/section/:id route
  resources :courses do
    resources :sections
  end

  resources :recommends, only: [ :new, :create, :update]do
    member do
      get 'show_section', to: 'recommends#show_section'
      get 'show_student', to: 'recommends#show_student'
      put 'approve_request', to: 'recommends#approve_request'
      put 'deny_request', to: 'recommends#deny_request'
    end
  end
  
  #instructor only: recommends
  #get 'recommends/new', to: 'recommends#new'
  # Reset database route
  post '/recommends', to: 'recommends#create'
  post 'recommends/:request_id/choose_section/:section_id', to: 'recommends#choose_section', as: 'choose_section_request'
  get 'recommends/show_student/:request_id', to: 'recommends#show_student', as: 'unique_show_student_recommend'

  # config/routes.rb
  resources :role_requests, only: [:index] do
    member do
      put 'approve'
      put 'deny'
    end
  end

  resources :applications , only: [:index, :show] do
    member do
      patch 'approve', to: 'applications#approve'
      patch 'deny', to: 'applications#deny'
      get 'assign_grader'
    end
  end

  resources :real_applications, only: [:new, :create, :edit, :update] do
    collection do
      get 'manage'
    end

    member do
      get 'show_section'
      get 'show_applicant'
      put 'approve'
      put 'deny'
    end
  end

  post 'real_applications/:real_application_id/choose_section/:section_id', to: 'real_applications#choose_section', as: 'choose_section_real_application'
  


  resources :reload, only: [:index] 
  post 'reload_OSU_API', to: 'reload#update'
  get 'reload_delete_all', to: 'reload#delete_all'
  
  get '*path', to: redirect('/')

end