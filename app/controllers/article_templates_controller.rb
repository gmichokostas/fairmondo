class ArticleTemplatesController < InheritedResources::Base

  before_filter :authenticate_user!
  before_filter :build_resource, :only => [:new, :create]
  before_filter :build_article, :only => [:new,:create]
  actions :all, :except => [:show,:index]



  def begin_of_association_chain
    current_user
  end

  # def collection
  #   @article_templates ||= end_of_association_chain.paginate(:page => params[:page])
  # end


  def update
    authorize resource
    update!  do |success, failure|
       success.html { redirect_to collection_url}
       failure.html { save_images
                      render :edit}
    end
  end

  def create
    authorize build_resource
    create! do |success, failure|
       success.html { redirect_to collection_url}
       failure.html { save_images
                      render :new}
    end
  end

  def edit
    authorize resource
    edit!
  end

  def new
    authorize resource
    new!
  end

  def destroy
    authorize resource
    destroy! {collection_url}
  end

  private

  def collection_url
    user_path(current_user, :anchor => "my_article_templates")
  end

  def build_article
    resource.build_article unless resource.article
    resource.article.seller = current_user
  end

  def save_images
    #At least try to save the images -> not persisted in browser
    if resource.article
      resource.article.images.each do |image|
        ## I tried for hours but couldn't figure out a way to write a test that transmit a wrong image.
        ## If the image removal is ever needed, comment it back in. ArticlesController doesn't use it either. -KK
        # if image.image
          image.save
        # else
        #   @article.images.remove image
        # end
      end
    end
  end

end
